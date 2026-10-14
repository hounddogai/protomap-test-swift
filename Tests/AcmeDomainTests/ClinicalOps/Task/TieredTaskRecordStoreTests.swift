@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredTaskRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredTaskRecordStore = ClinicalOps.newMemoryTieredTaskRecordStore()
        let item = ClinicalOps.newTieredTaskRecord("code-554", label: "label-908")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
