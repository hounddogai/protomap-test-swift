@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryAdaptiveBedBoardSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.AdaptiveBedBoardSlotStore = BedManagement.newMemoryAdaptiveBedBoardSlotStore()
        let item = BedManagement.newAdaptiveBedBoardSlot("code-582", name: "name-127")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
