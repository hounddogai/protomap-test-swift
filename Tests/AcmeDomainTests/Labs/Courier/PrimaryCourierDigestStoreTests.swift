@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPrimaryCourierDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PrimaryCourierDigestStore = Labs.newMemoryPrimaryCourierDigestStore()
        let item = Labs.newPrimaryCourierDigest("code-177", title: "title-297")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
