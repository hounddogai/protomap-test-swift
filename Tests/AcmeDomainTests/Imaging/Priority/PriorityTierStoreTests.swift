@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityTierStore = Imaging.newMemoryPriorityTierStore()
        let item = Imaging.newPriorityTier("code-729", label: "label-308")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
