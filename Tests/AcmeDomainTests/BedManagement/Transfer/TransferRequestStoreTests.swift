@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferRequestStore = BedManagement.newMemoryTransferRequestStore()
        let item = BedManagement.newTransferRequest("code-284", label: "label-127")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
