@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryFallbackStudySlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.FallbackStudySlotStore = Imaging.newMemoryFallbackStudySlotStore()
        let item = Imaging.newFallbackStudySlot("code-179", title: "title-305")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
