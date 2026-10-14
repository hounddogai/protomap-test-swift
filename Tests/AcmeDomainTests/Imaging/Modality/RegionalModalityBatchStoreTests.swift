@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalModalityBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalModalityBatchStore = Imaging.newMemoryRegionalModalityBatchStore()
        let item = Imaging.newRegionalModalityBatch("code-925", label: "label-150")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
