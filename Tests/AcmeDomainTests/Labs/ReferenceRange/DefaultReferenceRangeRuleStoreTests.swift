@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultReferenceRangeRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultReferenceRangeRuleStore = Labs.newMemoryDefaultReferenceRangeRuleStore()
        let item = Labs.newDefaultReferenceRangeRule("code-147", title: "title-495")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
