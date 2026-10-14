@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemorySeasonalCleaningManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.SeasonalCleaningManifestStore = BedManagement.newMemorySeasonalCleaningManifestStore()
        let item = BedManagement.newSeasonalCleaningManifest("code-229", name: "name-788")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
