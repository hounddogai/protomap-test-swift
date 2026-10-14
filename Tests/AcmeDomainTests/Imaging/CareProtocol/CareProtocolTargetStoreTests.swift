@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolTargetStore = Imaging.newMemoryCareProtocolTargetStore()
        let item = Imaging.newCareProtocolTarget("code-420", title: "title-876")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
