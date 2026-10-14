@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenOverrideStore = Labs.newMemorySpecimenOverrideStore()
        let item = Labs.newSpecimenOverride("code-75", title: "title-537")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
