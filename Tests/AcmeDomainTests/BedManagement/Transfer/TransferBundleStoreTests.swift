@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferBundleStore = BedManagement.newMemoryTransferBundleStore()
        let item = BedManagement.newTransferBundle("code-913", name: "name-314")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
