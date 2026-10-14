@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptivePriorityOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptivePriorityOverrideStore = Imaging.newMemoryAdaptivePriorityOverrideStore()
        let item = Imaging.newAdaptivePriorityOverride("code-361", label: "label-327")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
