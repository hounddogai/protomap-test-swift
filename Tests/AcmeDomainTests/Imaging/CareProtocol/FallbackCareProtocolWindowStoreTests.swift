@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryFallbackCareProtocolWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.FallbackCareProtocolWindowStore = Imaging.newMemoryFallbackCareProtocolWindowStore()
        let item = Imaging.newFallbackCareProtocolWindow("code-739", title: "title-469")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
