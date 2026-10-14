@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialAllocationStore = RevenueCycle.newMemoryDenialAllocationStore()
        let item = RevenueCycle.newDenialAllocation("code-638", title: "title-320")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
