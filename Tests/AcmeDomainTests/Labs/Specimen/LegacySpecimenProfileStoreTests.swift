@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacySpecimenProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacySpecimenProfileStore = Labs.newMemoryLegacySpecimenProfileStore()
        let item = Labs.newLegacySpecimenProfile("code-51", label: "label-688")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
