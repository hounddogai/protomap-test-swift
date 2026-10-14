@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertRecordStore = ClinicalOps.newMemoryAlertRecordStore()
        let item = ClinicalOps.newAlertRecord("code-412", label: "label-150")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
