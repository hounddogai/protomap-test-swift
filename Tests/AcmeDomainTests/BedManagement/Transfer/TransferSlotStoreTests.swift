@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferSlotStore = BedManagement.newMemoryTransferSlotStore()
        let item = BedManagement.newTransferSlot("code-711", title: "title-657")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
