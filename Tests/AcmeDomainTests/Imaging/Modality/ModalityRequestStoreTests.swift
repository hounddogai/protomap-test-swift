@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityRequestStore = Imaging.newMemoryModalityRequestStore()
        let item = Imaging.newModalityRequest("code-773", title: "title-526")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
