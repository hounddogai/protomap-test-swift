@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryDefaultReadBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.DefaultReadBaselineStore = Imaging.newMemoryDefaultReadBaselineStore()
        let item = Imaging.newDefaultReadBaseline("code-880", name: "name-788")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
