@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryGlobalReadSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.GlobalReadSlotStore = Imaging.newMemoryGlobalReadSlotStore()
        let item = Imaging.newGlobalReadSlot("code-189", name: "name-254")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
