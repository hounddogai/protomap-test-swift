@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRegionalStatementBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RegionalStatementBaselineStore = RevenueCycle.newMemoryRegionalStatementBaselineStore()
        let item = RevenueCycle.newRegionalStatementBaseline("code-544", label: "label-902")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
