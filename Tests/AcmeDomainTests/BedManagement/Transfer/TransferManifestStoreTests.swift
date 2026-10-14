@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferManifestStore = BedManagement.newMemoryTransferManifestStore()
        let item = BedManagement.newTransferManifest("code-43", name: "name-441")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
