@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWeightedModalityTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WeightedModalityTierStore = Imaging.newMemoryWeightedModalityTierStore()
        let item = Imaging.newWeightedModalityTier("code-52", name: "name-156")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
