@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientRemittanceSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientRemittanceSlotStore = RevenueCycle.newMemoryLenientRemittanceSlotStore()
        let item = RevenueCycle.newLenientRemittanceSlot("code-452", title: "title-731")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
