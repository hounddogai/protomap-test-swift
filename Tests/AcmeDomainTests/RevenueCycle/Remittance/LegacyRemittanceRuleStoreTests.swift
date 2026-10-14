@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyRemittanceRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyRemittanceRuleStore = RevenueCycle.newMemoryLegacyRemittanceRuleStore()
        let item = RevenueCycle.newLegacyRemittanceRule("code-335", name: "name-173")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
