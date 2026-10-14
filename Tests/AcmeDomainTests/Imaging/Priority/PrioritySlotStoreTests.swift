@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrioritySlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrioritySlotStore = Imaging.newMemoryPrioritySlotStore()
        let item = Imaging.newPrioritySlot("code-422", title: "title-83")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
