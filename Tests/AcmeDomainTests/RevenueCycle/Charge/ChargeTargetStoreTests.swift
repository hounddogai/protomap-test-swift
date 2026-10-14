@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeTargetStore = RevenueCycle.newMemoryChargeTargetStore()
        let item = RevenueCycle.newChargeTarget("code-909", title: "title-541")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
