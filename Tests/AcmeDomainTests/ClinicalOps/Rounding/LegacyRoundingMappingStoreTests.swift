@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLegacyRoundingMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LegacyRoundingMappingStore = ClinicalOps.newMemoryLegacyRoundingMappingStore()
        let item = ClinicalOps.newLegacyRoundingMapping("code-242", title: "title-385")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
