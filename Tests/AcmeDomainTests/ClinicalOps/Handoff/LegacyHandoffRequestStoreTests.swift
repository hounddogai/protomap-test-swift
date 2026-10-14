@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLegacyHandoffRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LegacyHandoffRequestStore = ClinicalOps.newMemoryLegacyHandoffRequestStore()
        let item = ClinicalOps.newLegacyHandoffRequest("code-732", label: "label-236")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
