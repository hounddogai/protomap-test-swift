@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeBudgetStore = RevenueCycle.newMemoryChargeBudgetStore()
        let item = RevenueCycle.newChargeBudget("code-436", name: "name-195")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
