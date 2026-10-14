@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenRuleStore = Labs.newMemorySpecimenRuleStore()
        let item = Labs.newSpecimenRule("code-676", title: "title-472")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
