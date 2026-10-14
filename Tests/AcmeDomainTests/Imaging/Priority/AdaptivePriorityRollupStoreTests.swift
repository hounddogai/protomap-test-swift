@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptivePriorityRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptivePriorityRollupStore = Imaging.newMemoryAdaptivePriorityRollupStore()
        let item = Imaging.newAdaptivePriorityRollup("code-761", label: "label-817")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
