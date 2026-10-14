@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptivePanelDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptivePanelDigestStore = Labs.newMemoryAdaptivePanelDigestStore()
        let item = Labs.newAdaptivePanelDigest("code-810", title: "title-357")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
