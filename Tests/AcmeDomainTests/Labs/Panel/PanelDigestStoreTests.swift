@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelDigestStore = Labs.newMemoryPanelDigestStore()
        let item = Labs.newPanelDigest("code-625", name: "name-179")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
