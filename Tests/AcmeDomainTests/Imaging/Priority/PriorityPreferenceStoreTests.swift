@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityPreferenceStore = Imaging.newMemoryPriorityPreferenceStore()
        let item = Imaging.newPriorityPreference("code-469", name: "name-731")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
