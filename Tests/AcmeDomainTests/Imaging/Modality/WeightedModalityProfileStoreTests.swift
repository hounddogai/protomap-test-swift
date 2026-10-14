@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWeightedModalityProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WeightedModalityProfileStore = Imaging.newMemoryWeightedModalityProfileStore()
        let item = Imaging.newWeightedModalityProfile("code-330", name: "name-692")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
