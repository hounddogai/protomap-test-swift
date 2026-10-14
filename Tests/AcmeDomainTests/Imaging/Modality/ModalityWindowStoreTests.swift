@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityWindowStore = Imaging.newMemoryModalityWindowStore()
        let item = Imaging.newModalityWindow("code-647", label: "label-499")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
