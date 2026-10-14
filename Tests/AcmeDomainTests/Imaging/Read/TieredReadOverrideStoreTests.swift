@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredReadOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredReadOverrideStore = Imaging.newMemoryTieredReadOverrideStore()
        let item = Imaging.newTieredReadOverride("code-908", label: "label-266")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
