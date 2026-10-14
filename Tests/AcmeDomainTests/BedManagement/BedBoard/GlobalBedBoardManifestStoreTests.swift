@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryGlobalBedBoardManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.GlobalBedBoardManifestStore = BedManagement.newMemoryGlobalBedBoardManifestStore()
        let item = BedManagement.newGlobalBedBoardManifest("code-586", label: "label-940")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
