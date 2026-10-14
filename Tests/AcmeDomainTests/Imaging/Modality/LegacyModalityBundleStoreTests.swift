@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLegacyModalityBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LegacyModalityBundleStore = Imaging.newMemoryLegacyModalityBundleStore()
        let item = Imaging.newLegacyModalityBundle("code-772", name: "name-141")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
