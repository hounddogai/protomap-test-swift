@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationAllocationStore = RevenueCycle.newMemoryAuthorizationAllocationStore()
        let item = RevenueCycle.newAuthorizationAllocation("code-117", name: "name-252")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
