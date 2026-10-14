@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolCheckpointStore = Imaging.newMemoryCareProtocolCheckpointStore()
        let item = Imaging.newCareProtocolCheckpoint("code-808", title: "title-569")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
