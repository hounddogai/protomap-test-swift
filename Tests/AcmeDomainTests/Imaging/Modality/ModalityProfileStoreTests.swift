@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityProfileStore = Imaging.newMemoryModalityProfileStore()
        let item = Imaging.newModalityProfile("code-802", title: "title-123")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
