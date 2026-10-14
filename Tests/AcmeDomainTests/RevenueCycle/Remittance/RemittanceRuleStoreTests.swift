@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceRuleStore = RevenueCycle.newMemoryRemittanceRuleStore()
        let item = RevenueCycle.newRemittanceRule("code-307", title: "title-724")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
