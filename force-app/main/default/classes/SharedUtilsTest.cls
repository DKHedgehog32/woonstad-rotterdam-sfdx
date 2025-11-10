/**
 * Created by harm on 02/09/2024.
 */
@IsTest
private class SharedUtilsTest {
    @IsTest
    private static void testPicklistSet() {
        Test.startTest();
        Integer totalCount = Account.Type.getDescribe().getPicklistValues().size();
        Set<String> strings = SharedUtils.convertPicklistValuesToSet(Account.Type.getDescribe());
        System.assertEquals(totalCount, strings.size(), 'Expected matching counts');
        Test.stopTest();
    }
}