@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictClaimAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictClaimAllocationStore = RevenueCycle.newMemoryStrictClaimAllocationStore()
        let item = RevenueCycle.newStrictClaimAllocation("code-993", label: "label-945")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
