@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultTaskRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultTaskRecordStore = ClinicalOps.newMemoryDefaultTaskRecordStore()
        let item = ClinicalOps.newDefaultTaskRecord("code-615", label: "label-405")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
