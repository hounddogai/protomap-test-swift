@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptiveStudyManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptiveStudyManifestStore = Imaging.newMemoryAdaptiveStudyManifestStore()
        let item = Imaging.newAdaptiveStudyManifest("code-558", label: "label-867")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
