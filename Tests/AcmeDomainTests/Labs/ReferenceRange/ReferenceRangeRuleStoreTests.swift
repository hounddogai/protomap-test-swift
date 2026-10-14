@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeRuleStore = Labs.newMemoryReferenceRangeRuleStore()
        let item = Labs.newReferenceRangeRule("code-49", label: "label-735")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
