@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferEntryStore = BedManagement.newMemoryTransferEntryStore()
        let item = BedManagement.newTransferEntry("code-131", label: "label-333")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
