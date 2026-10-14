@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalStudyBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalStudyBatchStore = Imaging.newMemoryRegionalStudyBatchStore()
        let item = Imaging.newRegionalStudyBatch("code-908", label: "label-636")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
