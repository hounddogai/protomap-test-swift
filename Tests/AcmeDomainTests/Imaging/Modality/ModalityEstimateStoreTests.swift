@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityEstimateStore = Imaging.newMemoryModalityEstimateStore()
        let item = Imaging.newModalityEstimate("code-958", label: "label-664")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
