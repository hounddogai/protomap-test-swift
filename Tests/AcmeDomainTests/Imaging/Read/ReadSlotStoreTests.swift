@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadSlotStore = Imaging.newMemoryReadSlotStore()
        let item = Imaging.newReadSlot("code-190", label: "label-379")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
