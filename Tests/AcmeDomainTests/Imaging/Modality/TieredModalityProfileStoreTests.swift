@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredModalityProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredModalityProfileStore = Imaging.newMemoryTieredModalityProfileStore()
        let item = Imaging.newTieredModalityProfile("code-934", name: "name-228")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
