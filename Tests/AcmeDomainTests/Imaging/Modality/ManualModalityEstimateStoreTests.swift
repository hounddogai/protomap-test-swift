@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualModalityEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualModalityEstimateStore = Imaging.newMemoryManualModalityEstimateStore()
        let item = Imaging.newManualModalityEstimate("code-846", label: "label-238")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
