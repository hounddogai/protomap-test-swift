@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedAccessionRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedAccessionRuleStore = Labs.newMemoryWeightedAccessionRuleStore()
        let item = Labs.newWeightedAccessionRule("code-788", title: "title-174")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
