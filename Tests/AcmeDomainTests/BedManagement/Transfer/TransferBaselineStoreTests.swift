@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferBaselineStore = BedManagement.newMemoryTransferBaselineStore()
        let item = BedManagement.newTransferBaseline("code-971", label: "label-591")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
