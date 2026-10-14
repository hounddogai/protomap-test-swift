@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBatchedCleaningRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BatchedCleaningRecordStore = BedManagement.newMemoryBatchedCleaningRecordStore()
        let item = BedManagement.newBatchedCleaningRecord("code-535", label: "label-737")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
