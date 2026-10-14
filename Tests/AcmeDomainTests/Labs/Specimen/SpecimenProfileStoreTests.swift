@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenProfileStore = Labs.newMemorySpecimenProfileStore()
        let item = Labs.newSpecimenProfile("code-737", name: "name-452")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
