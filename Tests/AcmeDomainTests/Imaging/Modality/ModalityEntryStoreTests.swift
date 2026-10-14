@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityEntryStore = Imaging.newMemoryModalityEntryStore()
        let item = Imaging.newModalityEntry("code-969", label: "label-566")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
