@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityThresholdStore = Imaging.newMemoryModalityThresholdStore()
        let item = Imaging.newModalityThreshold("code-766", title: "title-381")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
