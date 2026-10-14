@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLegacyCareProtocolPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LegacyCareProtocolPreferenceStore = Imaging.newMemoryLegacyCareProtocolPreferenceStore()
        let item = Imaging.newLegacyCareProtocolPreference("code-589", title: "title-395")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
