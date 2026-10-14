@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenPolicyStore = Labs.newMemorySpecimenPolicyStore()
        let item = Labs.newSpecimenPolicy("code-226", title: "title-359")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
