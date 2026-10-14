@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryFallbackModalityEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.FallbackModalityEntryStore = Imaging.newMemoryFallbackModalityEntryStore()
        let item = Imaging.newFallbackModalityEntry("code-716", name: "name-777")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
