@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingModalityPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingModalityPolicyStore = Imaging.newMemoryPendingModalityPolicyStore()
        let item = Imaging.newPendingModalityPolicy("code-626", title: "title-304")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
