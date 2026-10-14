@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningAdjustmentStore = BedManagement.newMemoryCleaningAdjustmentStore()
        let item = BedManagement.newCleaningAdjustment("code-927", label: "label-937")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
