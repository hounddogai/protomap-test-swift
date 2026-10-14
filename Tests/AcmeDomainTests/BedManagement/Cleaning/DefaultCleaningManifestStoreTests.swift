@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDefaultCleaningManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DefaultCleaningManifestStore = BedManagement.newMemoryDefaultCleaningManifestStore()
        let item = BedManagement.newDefaultCleaningManifest("code-736", label: "label-953")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
