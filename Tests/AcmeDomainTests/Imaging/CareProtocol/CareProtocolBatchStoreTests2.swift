@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolBatchStore = Imaging.newMemoryCareProtocolBatchStore()
        let item = Imaging.newCareProtocolBatch("code-678", name: "name-965")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
