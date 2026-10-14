@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadPreferenceStore = Imaging.newMemoryReadPreferenceStore()
        let item = Imaging.newReadPreference("code-373", label: "label-872")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
