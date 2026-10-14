@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBatchedCleaningOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BatchedCleaningOverrideStore = BedManagement.newMemoryBatchedCleaningOverrideStore()
        let item = BedManagement.newBatchedCleaningOverride("code-130", title: "title-668")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
