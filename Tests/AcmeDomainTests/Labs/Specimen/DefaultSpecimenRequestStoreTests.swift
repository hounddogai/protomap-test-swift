@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultSpecimenRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultSpecimenRequestStore = Labs.newMemoryDefaultSpecimenRequestStore()
        let item = Labs.newDefaultSpecimenRequest("code-392", name: "name-277")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
