@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedCareProtocolPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedCareProtocolPreferenceStore = Imaging.newMemoryCappedCareProtocolPreferenceStore()
        let item = Imaging.newCappedCareProtocolPreference("code-369", title: "title-271")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
