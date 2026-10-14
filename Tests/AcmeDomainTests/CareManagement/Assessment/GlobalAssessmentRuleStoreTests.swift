@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalAssessmentRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalAssessmentRuleStore = CareManagement.newMemoryGlobalAssessmentRuleStore()
        let item = CareManagement.newGlobalAssessmentRule("code-528", name: "name-183")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
