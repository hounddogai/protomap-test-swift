@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialSlotStore = RevenueCycle.newMemoryDenialSlotStore()
        let item = RevenueCycle.newDenialSlot("code-251", label: "label-244")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
