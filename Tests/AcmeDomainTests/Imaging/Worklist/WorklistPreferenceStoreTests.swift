@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistPreferenceStore = Imaging.newMemoryWorklistPreferenceStore()
        let item = Imaging.newWorklistPreference("code-186", title: "title-77")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
