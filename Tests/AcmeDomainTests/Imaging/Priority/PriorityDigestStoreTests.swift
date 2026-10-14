@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityDigestStore = Imaging.newMemoryPriorityDigestStore()
        let item = Imaging.newPriorityDigest("code-27", title: "title-228")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
