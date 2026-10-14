@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPrimaryRemittancePlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PrimaryRemittancePlanStore = RevenueCycle.newMemoryPrimaryRemittancePlanStore()
        let item = RevenueCycle.newPrimaryRemittancePlan("code-832", name: "name-978")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
