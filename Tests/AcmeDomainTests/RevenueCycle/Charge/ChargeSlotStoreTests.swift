@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeSlotStore = RevenueCycle.newMemoryChargeSlotStore()
        let item = RevenueCycle.newChargeSlot("code-510", label: "label-524")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
