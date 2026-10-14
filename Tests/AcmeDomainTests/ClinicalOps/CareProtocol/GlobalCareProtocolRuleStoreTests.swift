@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalCareProtocolRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalCareProtocolRuleStore = ClinicalOps.newMemoryGlobalCareProtocolRuleStore()
        let item = ClinicalOps.newGlobalCareProtocolRule("code-270", title: "title-913")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
