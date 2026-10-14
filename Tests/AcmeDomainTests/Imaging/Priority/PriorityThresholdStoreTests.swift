@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityThresholdStore = Imaging.newMemoryPriorityThresholdStore()
        let item = Imaging.newPriorityThreshold("code-955", name: "name-900")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
