@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenGroupStore = Labs.newMemorySpecimenGroupStore()
        let item = Labs.newSpecimenGroup("code-84", name: "name-255")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
