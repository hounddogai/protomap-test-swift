@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryFallbackCareProtocolPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.FallbackCareProtocolPolicyStore = Imaging.newMemoryFallbackCareProtocolPolicyStore()
        let item = Imaging.newFallbackCareProtocolPolicy("code-962", title: "title-368")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
