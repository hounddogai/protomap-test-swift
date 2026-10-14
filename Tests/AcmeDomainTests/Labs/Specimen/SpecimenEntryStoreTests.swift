@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenEntryStore = Labs.newMemorySpecimenEntryStore()
        let item = Labs.newSpecimenEntry("code-1", label: "label-929")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
