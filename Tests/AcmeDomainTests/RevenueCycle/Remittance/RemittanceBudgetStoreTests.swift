@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceBudgetStore = RevenueCycle.newMemoryRemittanceBudgetStore()
        let item = RevenueCycle.newRemittanceBudget("code-957", title: "title-143")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
