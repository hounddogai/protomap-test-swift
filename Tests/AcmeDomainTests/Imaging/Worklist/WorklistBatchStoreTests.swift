@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistBatchStore = Imaging.newMemoryWorklistBatchStore()
        let item = Imaging.newWorklistBatch("code-614", label: "label-489")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
