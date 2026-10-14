@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferAssignmentStore = BedManagement.newMemoryTransferAssignmentStore()
        let item = BedManagement.newTransferAssignment("code-192", label: "label-60")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
