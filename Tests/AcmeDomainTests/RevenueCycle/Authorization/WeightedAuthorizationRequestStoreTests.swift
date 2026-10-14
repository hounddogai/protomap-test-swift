@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryWeightedAuthorizationRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.WeightedAuthorizationRequestStore = RevenueCycle.newMemoryWeightedAuthorizationRequestStore()
        let item = RevenueCycle.newWeightedAuthorizationRequest("code-24", title: "title-124")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
