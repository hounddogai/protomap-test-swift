@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualCareProtocolSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualCareProtocolSlotStore = Imaging.newMemoryManualCareProtocolSlotStore()
        let item = Imaging.newManualCareProtocolSlot("code-646", label: "label-866")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
