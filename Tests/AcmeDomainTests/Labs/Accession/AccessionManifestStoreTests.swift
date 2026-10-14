@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionManifestStore = Labs.newMemoryAccessionManifestStore()
        let item = Labs.newAccessionManifest("code-73", label: "label-195")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
