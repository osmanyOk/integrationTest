@isTest (SeeAllData=true)
public class BroadcastAnnouncemBlogControllerTest {

	static testMethod void BroadcastArticleTest(){

        BroadcastAnnouncementsAndBlogController myController = new BroadcastAnnouncementsAndBlogController();
        myController.cleanAll();
        myController.filter = '*';
        myController.searchArticle();        
        myController.filter = 'text';
        myController.searchArticle();         
        myController.artAnnouncement = [SELECT Id, Title, KnowledgeArticleId, Summary, PublishStatus, ArticleType, LastPublishedDate FROM ArticleType__kav WHERE Language = 'en_US' AND PublishStatus = 'Online'];
        
        myController.articleId = myController.artAnnouncement[0].Id;
        myController.selectArticle();

        String listAddArt;        
        String listDelArt;
        Set<Id> topicIds = new Set<Id>();

        for( Topic to: [ SELECT Id FROM Topic WHERE NetworkId != null LIMIT 100 ]) {
            if( String.isEmpty(listAddArt) ) {
                listAddArt = to.Id;
            } else {
                listAddArt += ',' + to.Id;
            }
            topicIds.add(to.Id);
        }
        myController.addedToTopic = listAddArt;
        myController.removeFromTopic = '';
        myController.broadcastArticle(); 
        myController.removeFromTopic = listAddArt;
        myController.broadcastArticle();        
	}


    static testMethod void getMethods(){
        BroadcastAnnouncementsAndBlogController myController = new BroadcastAnnouncementsAndBlogController();
        String fi = myController.getFilter();
        Boolean re = myController.getResult();
        String art = myController.getArticleId();
        String addTop = myController.getAddedToTopic();
        String delTop = myController.getRemoveFromTopic(); 
        List<ArticleType__kav> la = myController.getArtAnnouncement();
        List<BroadcastAnnouncementsAndBlogController.TopicCommunityRow> l = myController.getTopicCommunityRow();
        BroadcastAnnouncementsAndBlogController.TopicCommunityRow rowTopic = new BroadcastAnnouncementsAndBlogController.TopicCommunityRow ('0EP38000000CzpT', true, 'pTopicName', true, 'pParentName', 'pCommunityName', 'pCommunityStatus');

        rowTopic.getTopicName();        
        rowTopic.getTopicId();

        rowTopic.getTopicName(); 
        rowTopic.getIsPostedTo(); 
        rowTopic.getCommunityName(); 

        rowTopic.getParentName();
        rowTopic.getIsSubTopic();
        rowTopic.getCommunityStatus();
    }
}