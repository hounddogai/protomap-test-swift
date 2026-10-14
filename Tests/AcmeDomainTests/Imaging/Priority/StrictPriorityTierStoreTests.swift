@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStrictPriorityTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StrictPriorityTierStore = Imaging.newMemoryStrictPriorityTierStore()
        let item = Imaging.newStrictPriorityTier("code-527", label: "label-999")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
