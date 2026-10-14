@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRollingRemittanceEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RollingRemittanceEstimateStore = RevenueCycle.newMemoryRollingRemittanceEstimateStore()
        let item = RevenueCycle.newRollingRemittanceEstimate("code-566", label: "label-200")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
