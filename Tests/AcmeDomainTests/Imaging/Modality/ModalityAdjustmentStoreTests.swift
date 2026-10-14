@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityAdjustmentStore = Imaging.newMemoryModalityAdjustmentStore()
        let item = Imaging.newModalityAdjustment("code-580", label: "label-8")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
