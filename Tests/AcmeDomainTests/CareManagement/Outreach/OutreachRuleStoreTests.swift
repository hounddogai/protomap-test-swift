@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachRuleStore = CareManagement.newMemoryOutreachRuleStore()
        let item = CareManagement.newOutreachRule("code-991", title: "title-284")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
