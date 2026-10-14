@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolClaimStore = Imaging.newMemoryCareProtocolClaimStore()
        let item = Imaging.newCareProtocolClaim("code-834", title: "title-799")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
