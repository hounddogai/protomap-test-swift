@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedModalityPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedModalityPreferenceStore = Imaging.newMemoryCappedModalityPreferenceStore()
        let item = Imaging.newCappedModalityPreference("code-619", title: "title-350")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
