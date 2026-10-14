@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWeightedCareProtocolRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WeightedCareProtocolRollupStore = Imaging.newMemoryWeightedCareProtocolRollupStore()
        let item = Imaging.newWeightedCareProtocolRollup("code-735", label: "label-753")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
