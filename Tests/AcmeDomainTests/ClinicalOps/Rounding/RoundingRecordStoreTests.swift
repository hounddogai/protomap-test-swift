@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingRecordStore = ClinicalOps.newMemoryRoundingRecordStore()
        let item = ClinicalOps.newRoundingRecord("code-251", label: "label-608")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
