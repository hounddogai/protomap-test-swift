@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalSpecimenRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalSpecimenRuleStore = Labs.newMemoryGlobalSpecimenRuleStore()
        let item = Labs.newGlobalSpecimenRule("code-950", title: "title-597")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
