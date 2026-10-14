@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningBatchStore = BedManagement.newMemoryCleaningBatchStore()
        let item = BedManagement.newCleaningBatch("code-359", label: "label-469")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
