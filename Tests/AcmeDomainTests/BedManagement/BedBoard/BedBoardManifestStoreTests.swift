@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardManifestStore = BedManagement.newMemoryBedBoardManifestStore()
        let item = BedManagement.newBedBoardManifest("code-369", name: "name-733")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
