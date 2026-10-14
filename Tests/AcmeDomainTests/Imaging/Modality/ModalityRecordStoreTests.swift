@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityRecordStore = Imaging.newMemoryModalityRecordStore()
        let item = Imaging.newModalityRecord("code-786", label: "label-835")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
