@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningSlotStore = BedManagement.newMemoryCleaningSlotStore()
        let item = BedManagement.newCleaningSlot("code-558", label: "label-528")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
