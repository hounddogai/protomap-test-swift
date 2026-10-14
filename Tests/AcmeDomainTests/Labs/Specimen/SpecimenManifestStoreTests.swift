@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenManifestStore = Labs.newMemorySpecimenManifestStore()
        let item = Labs.newSpecimenManifest("code-290", label: "label-273")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
