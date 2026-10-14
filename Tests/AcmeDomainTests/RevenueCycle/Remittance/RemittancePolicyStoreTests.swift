@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittancePolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittancePolicyStore = RevenueCycle.newMemoryRemittancePolicyStore()
        let item = RevenueCycle.newRemittancePolicy("code-665", title: "title-642")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
