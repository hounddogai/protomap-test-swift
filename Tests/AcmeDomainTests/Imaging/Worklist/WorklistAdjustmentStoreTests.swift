@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistAdjustmentStore = Imaging.newMemoryWorklistAdjustmentStore()
        let item = Imaging.newWorklistAdjustment("code-647", name: "name-51")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
