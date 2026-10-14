@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistSlotStore = Imaging.newMemoryWorklistSlotStore()
        let item = Imaging.newWorklistSlot("code-957", name: "name-998")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
