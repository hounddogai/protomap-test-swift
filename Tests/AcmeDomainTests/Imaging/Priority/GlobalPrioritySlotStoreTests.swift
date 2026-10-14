@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryGlobalPrioritySlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.GlobalPrioritySlotStore = Imaging.newMemoryGlobalPrioritySlotStore()
        let item = Imaging.newGlobalPrioritySlot("code-931", label: "label-71")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
