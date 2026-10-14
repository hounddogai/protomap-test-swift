@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryManualResultDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ManualResultDigestStore = Labs.newMemoryManualResultDigestStore()
        let item = Labs.newManualResultDigest("code-885", title: "title-570")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
