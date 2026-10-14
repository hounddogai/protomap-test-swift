@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistRequestStore = Imaging.newMemoryWorklistRequestStore()
        let item = Imaging.newWorklistRequest("code-555", label: "label-687")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
