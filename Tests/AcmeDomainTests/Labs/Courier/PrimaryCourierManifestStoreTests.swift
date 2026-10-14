@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPrimaryCourierManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PrimaryCourierManifestStore = Labs.newMemoryPrimaryCourierManifestStore()
        let item = Labs.newPrimaryCourierManifest("code-512", title: "title-761")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
