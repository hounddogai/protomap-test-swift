@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientClaimPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientClaimPolicyStore = RevenueCycle.newMemoryLenientClaimPolicyStore()
        let item = RevenueCycle.newLenientClaimPolicy("code-42", name: "name-282")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
