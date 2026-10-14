@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientOutreachRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientOutreachRuleStore = CareManagement.newMemoryLenientOutreachRuleStore()
        let item = CareManagement.newLenientOutreachRule("code-686", name: "name-488")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
