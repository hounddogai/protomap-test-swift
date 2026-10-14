@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledReferenceRangeRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledReferenceRangeRuleStore = Labs.newMemoryScheduledReferenceRangeRuleStore()
        let item = Labs.newScheduledReferenceRangeRule("code-496", name: "name-784")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
