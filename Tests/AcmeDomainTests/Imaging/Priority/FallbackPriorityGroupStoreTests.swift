@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryFallbackPriorityGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.FallbackPriorityGroupStore = Imaging.newMemoryFallbackPriorityGroupStore()
        let item = Imaging.newFallbackPriorityGroup("code-553", label: "label-687")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
