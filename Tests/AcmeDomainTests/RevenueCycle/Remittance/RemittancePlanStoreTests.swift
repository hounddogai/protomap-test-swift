@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittancePlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittancePlanStore = RevenueCycle.newMemoryRemittancePlanStore()
        let item = RevenueCycle.newRemittancePlan("code-396", title: "title-632")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
