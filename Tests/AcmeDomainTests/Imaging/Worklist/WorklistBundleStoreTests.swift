@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistBundleStore = Imaging.newMemoryWorklistBundleStore()
        let item = Imaging.newWorklistBundle("code-259", label: "label-566")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
