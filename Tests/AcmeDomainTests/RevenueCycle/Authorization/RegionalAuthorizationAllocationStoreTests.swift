@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRegionalAuthorizationAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RegionalAuthorizationAllocationStore = RevenueCycle.newMemoryRegionalAuthorizationAllocationStore()
        let item = RevenueCycle.newRegionalAuthorizationAllocation("code-943", label: "label-95")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
