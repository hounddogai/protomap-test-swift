@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultManifestStore = Labs.newMemoryResultManifestStore()
        let item = Labs.newResultManifest("code-936", label: "label-379")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
