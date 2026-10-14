@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenWindowStore = Labs.newMemorySpecimenWindowStore()
        let item = Labs.newSpecimenWindow("code-448", title: "title-971")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
