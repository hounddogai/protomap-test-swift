@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeManifestStore = Labs.newMemoryReferenceRangeManifestStore()
        let item = Labs.newReferenceRangeManifest("code-512", name: "name-245")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
