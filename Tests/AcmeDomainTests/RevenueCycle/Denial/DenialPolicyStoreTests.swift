@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialPolicyStore = RevenueCycle.newMemoryDenialPolicyStore()
        let item = RevenueCycle.newDenialPolicy("code-39", name: "name-25")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
