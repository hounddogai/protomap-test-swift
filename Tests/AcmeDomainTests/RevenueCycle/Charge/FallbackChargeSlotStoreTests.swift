@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackChargeSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackChargeSlotStore = RevenueCycle.newMemoryFallbackChargeSlotStore()
        let item = RevenueCycle.newFallbackChargeSlot("code-428", label: "label-18")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
