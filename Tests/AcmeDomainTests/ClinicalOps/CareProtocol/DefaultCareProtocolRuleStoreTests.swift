@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultCareProtocolRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultCareProtocolRuleStore = ClinicalOps.newMemoryDefaultCareProtocolRuleStore()
        let item = ClinicalOps.newDefaultCareProtocolRule("code-856", name: "name-799")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
