@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictAuthorizationSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictAuthorizationSlotStore = RevenueCycle.newMemoryStrictAuthorizationSlotStore()
        let item = RevenueCycle.newStrictAuthorizationSlot("code-733", title: "title-21")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
