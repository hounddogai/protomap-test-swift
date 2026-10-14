@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolPreferenceStore = Imaging.newMemoryCareProtocolPreferenceStore()
        let item = Imaging.newCareProtocolPreference("code-27", name: "name-976")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
