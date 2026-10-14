@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingEntryStore = ClinicalOps.newMemoryRoundingEntryStore()
        let item = ClinicalOps.newRoundingEntry("code-173", label: "label-639")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
