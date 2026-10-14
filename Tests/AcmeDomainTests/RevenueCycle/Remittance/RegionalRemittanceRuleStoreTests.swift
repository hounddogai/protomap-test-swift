@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRegionalRemittanceRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RegionalRemittanceRuleStore = RevenueCycle.newMemoryRegionalRemittanceRuleStore()
        let item = RevenueCycle.newRegionalRemittanceRule("code-942", label: "label-989")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
