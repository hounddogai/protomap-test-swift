@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferAdjustmentStore = BedManagement.newMemoryTransferAdjustmentStore()
        let item = BedManagement.newTransferAdjustment("code-34", title: "title-676")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
