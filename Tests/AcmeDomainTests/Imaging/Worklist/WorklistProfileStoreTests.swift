@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistProfileStore = Imaging.newMemoryWorklistProfileStore()
        let item = Imaging.newWorklistProfile("code-206", label: "label-894")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
