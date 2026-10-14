@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityClaimStore = Imaging.newMemoryPriorityClaimStore()
        let item = Imaging.newPriorityClaim("code-592", title: "title-151")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
