@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapRuleStore = CareManagement.newMemoryCareGapRuleStore()
        let item = CareManagement.newCareGapRule("code-123", name: "name-904")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
