@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolRequestStore = Imaging.newMemoryCareProtocolRequestStore()
        let item = Imaging.newCareProtocolRequest("code-232", label: "label-155")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
