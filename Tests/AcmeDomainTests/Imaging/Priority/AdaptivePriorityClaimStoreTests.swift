@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptivePriorityClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptivePriorityClaimStore = Imaging.newMemoryAdaptivePriorityClaimStore()
        let item = Imaging.newAdaptivePriorityClaim("code-421", label: "label-252")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
