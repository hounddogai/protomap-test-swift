@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadManifestStore = Imaging.newMemoryReadManifestStore()
        let item = Imaging.newReadManifest("code-513", name: "name-474")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
