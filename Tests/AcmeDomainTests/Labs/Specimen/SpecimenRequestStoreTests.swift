@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenRequestStore = Labs.newMemorySpecimenRequestStore()
        let item = Labs.newSpecimenRequest("code-169", name: "name-515")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
