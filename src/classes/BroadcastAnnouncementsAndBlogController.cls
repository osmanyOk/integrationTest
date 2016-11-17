public class BroadcastAnnouncementsAndBlogController {
	
	public Boolean result {get;set;}
	public String filter {get;set;} 
	public String articleId {get;set;}    
	public String addedToTopic {get;set;}
	public String removeFromTopic {get;set;}
	public List<TopicCommunityRow> topicCommunityRow {get;set;}    
	public List<ArticleType__kav> artAnnouncement {get;set;}
	
	public BroadcastAnnouncementsAndBlogController() {
		artAnnouncement = [SELECT Id, Title, KnowledgeArticleId, Summary, PublishStatus, ArticleType, LastPublishedDate FROM ArticleType__kav WHERE Language = 'en_US' AND PublishStatus = 'Online'];
		topicCommunityRow = new List<TopicCommunityRow>();
	}
	
	public String getFilter() { return filter; }
	public Boolean getResult() { return result; }
	public String getArticleId() { return articleId; }
	public String getAddedToTopic() { return addedToTopic; }
	public String getRemoveFromTopic() { return removeFromTopic; } 
	public List<ArticleType__kav> getArtAnnouncement() { return artAnnouncement; }
	public List<TopicCommunityRow> getTopicCommunityRow() { return topicCommunityRow; }
	
	
	//Search article and update article list with result
	public Pagereference searchArticle() {
		if( String.isNotBlank(filter) && filter != '*' ) {
			artAnnouncement = [ SELECT Id, Title, KnowledgeArticleId, Summary, PublishStatus, ArticleType, LastPublishedDate FROM ArticleType__kav WHERE Title LIKE: '%'+filter+'%' AND Language = 'en_US' AND PublishStatus = 'Online' ];        
		} else {
			artAnnouncement = [ SELECT Id, Title, KnowledgeArticleId, Summary, PublishStatus, ArticleType, LastPublishedDate FROM ArticleType__kav WHERE Language = 'en_US' AND PublishStatus = 'Online' ];
		}

		filter = '';
		topicCommunityRow = new List<TopicCommunityRow>();
		return New Pagereference( '/apex/BroadcastAnnouncementsAndBlogs' );
	}
	
	//show list de topic
	public Pagereference selectArticle() {
		topicCommunityRow = new List<TopicCommunityRow>();
	
		//Set with idTopic that have assigned 'articleId'
		Set<Id> idTopic = new Set<Id>();		
		for( TopicAssignment topAss : [ SELECT Id, EntityId, TopicId FROM TopicAssignment WHERE EntityId =: articleId ] ) {
			idTopic.add(topAss.TopicId);
		} 
	
		Boolean contains;
		for( Network com: [ SELECT Id,Name, Status FROM Network ORDER BY Name ASC NULLS FIRST ] ) {
			ConnectAPI.ManagedTopicCollection mtts = ConnectAPI.ManagedTopics.getManagedTopics( com.Id, ConnectApi.managedTopicType.Navigational, 2 );
			if( mtts != null ) {
				for( ConnectAPI.ManagedTopic mtt : mtts.managedTopics ) {
					contains = false;
					if( idTopic.contains( mtt.topic.Id ) ) {
						contains = true;
					}
					//topicCommunityRow.add( new TopicCommunityRow( mtt.topic.Id, com.Name, mtt.topic.name, contains ) );
					topicCommunityRow.add( new TopicCommunityRow( mtt.topic.Id, contains, mtt.topic.name, false, '---', com.Name, com.Status ) );
								
					if( mtt.children != null) {				
						for(ConnectAPI.ManagedTopic child : mtt.children ) {
							contains = false;
							if( idTopic.contains( child.topic.id ) ) {
								contains = true;
							}
							topicCommunityRow.add( new TopicCommunityRow( child.topic.id, contains, child.topic.name, true, mtt.topic.name, com.Name, com.Status ) );
						}
					}				
				}
			}
		}
		return null;
	}
	
	public Pagereference broadcastArticle() {
		try {
			if( String.isNotBlank( articleId ) ) {
				if( String.isNotBlank( addedToTopic ) ) {
					List<TopicAssignment> addTopicAssignment = getListTopicAssignment( addedToTopic, articleId, 1 );
					System.debug(LoggingLevel.ERROR, 'addTopicAssignment: ' +addTopicAssignment);									
					insert addTopicAssignment;	                 
				}
				if( String.isNotBlank( removeFromTopic ) ) {
					List<TopicAssignment> delTopicAssignment = getListTopicAssignment( removeFromTopic, articleId, 2 );					
					delete delTopicAssignment;                
				}
			}
		}
		catch (DmlException e) {
			System.debug( 'The following exception has occurred: ' + e.getMessage() );
		}
		cleanAll();
		return New Pagereference('/apex/BroadcastAnnouncementsAndBlogs');
	}
	
	public List<TopicAssignment> getListTopicAssignment( String pListTopic, String pArtId, Integer operations ) {
		
		List<TopicAssignment> re = new List<TopicAssignment>();
		List<String> listTopic = new List<String>( pListTopic.split(',') );	
		
		Set<String> setTopic = new Set<String>( listTopic );
		Map<Id,Topic> mapTopic = new Map<Id,Topic>( [ SELECT Id, NetworkId FROM Topic WHERE Id IN: setTopic ] );

		Map<Id,Set<Id>> mapTopicId_SetEntity = new Map<Id,Set<Id>>();

		for(TopicAssignment topicA : [ SELECT EntityId, TopicId FROM TopicAssignment WHERE NetworkId != null ] ) {
			if( mapTopicId_SetEntity.get(topicA.TopicId) == null ) {
				mapTopicId_SetEntity.put(topicA.TopicId, new Set<Id>() );

			}
			mapTopicId_SetEntity.get(topicA.TopicId).add( topicA.EntityId);
		}
		
		//Map<String,Set<Id>> mapTopic_SetSubTopic = getSubTopics( setTopic );
		if( operations == 1 ) {//the DML operation is to insert			
			for( String topId : listTopic ) {
				re.add( new TopicAssignment(
					TopicId = topId,
					EntityId = pArtId,
					NetworkId = mapTopic.get(topId).NetworkId
					)
				);

				//If it have a parent to assign Entity Id to parent also
				ConnectAPI.ManagedTopicCollection mtts = ConnectAPI.ManagedTopics.getManagedTopics( mapTopic.get(topId).NetworkId, ConnectApi.managedTopicType.Navigational, topId,2 );
				if( mtts != null && !mtts.managedTopics.isEmpty()) {
					ConnectAPI.ManagedTopic mtt = mtts.managedTopics[0];
					ConnectApi.Reference parent = mtt.parent;

					if( parent != null ) {
						ConnectApi.ManagedTopic mttParent = ConnectAPI.ManagedTopics.getManagedTopic( mapTopic.get(topId).NetworkId, parent.id );
					
						if( !mapTopicId_SetEntity.isEmpty() && !mapTopicId_SetEntity.get(mttParent.topic.Id).contains(pArtId) ) {
							re.add( new TopicAssignment(
								TopicId = mttParent.topic.Id,
								EntityId = pArtId,
								NetworkId = mapTopic.get(topId).NetworkId
								)
							);						
						}
					}
				}
			}            
		} else if( operations == 2 ) {//the DML operation is to delete
			Set<String> childTopic = new Set<String>();			
			if( !childTopic.isEmpty() ) { setTopic.addAll( childTopic ); }
			re = [ SELECT Id, EntityId, TopicId FROM TopicAssignment WHERE EntityId =: pArtId AND TopicId IN: setTopic ];
		}
		return re;
	}
	
	public class TopicCommunityRow{		
		public Id topicId {get;set;}
		public String topicName {get;set;}
		public Boolean isPostedTo {get;set;}
		public String communityName {get;set;}
		
		public String parentName {get;set;}
		public Boolean isSubTopic {get;set;}
		public String communityStatus {get;set;}
		
		//public TopicCommunityRow( Id pTopicId, String pCommunityName, String pTopicName, Boolean pIsPostedTo ){
		public TopicCommunityRow( Id pTopicId, Boolean pIsPostedTo, String pTopicName, Boolean pIsSubTopic, String pParentName, String pCommunityName, String pCommunityStatus ){
			topicId = pTopicId;
			isPostedTo = pIsPostedTo; 
			topicName = pTopicName;
			isSubTopic = pIsSubTopic;
			parentName = pParentName;
			communityName = pCommunityName;	
			communityStatus = pCommunityStatus;		           
		}
		
		public Id getTopicId() { return topicId; }
		public String getTopicName() { return topicName; }
		public Boolean getIsPostedTo() { return isPostedTo; }
		public String getCommunityName() { return communityName; }

		public String getParentName() { return parentName; }
		public Boolean getIsSubTopic() { return isSubTopic; }
		public String getCommunityStatus() { return communityStatus; }
	}

	public void cleanAll() {
		filter = '';
		artAnnouncement = [ SELECT Id, Title, KnowledgeArticleId, Summary, PublishStatus, ArticleType, LastPublishedDate FROM ArticleType__kav WHERE Language = 'en_US' AND PublishStatus = 'Online' ];
		topicCommunityRow = new List<TopicCommunityRow>();
	}
}