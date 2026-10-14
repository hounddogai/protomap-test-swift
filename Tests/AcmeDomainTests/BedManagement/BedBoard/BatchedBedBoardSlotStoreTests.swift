@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBatchedBedBoardSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BatchedBedBoardSlotStore = BedManagement.newMemoryBatchedBedBoardSlotStore()
        let item = BedManagement.newBatchedBedBoardSlot("code-329", title: "title-713")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
