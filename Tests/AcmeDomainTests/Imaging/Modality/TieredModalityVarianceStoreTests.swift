@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredModalityVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredModalityVarianceStore = Imaging.newMemoryTieredModalityVarianceStore()
        let item = Imaging.newTieredModalityVariance("code-866", name: "name-440")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
