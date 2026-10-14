@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationEstimateStore = RevenueCycle.newMemoryAuthorizationEstimateStore()
        let item = RevenueCycle.newAuthorizationEstimate("code-714", title: "title-774")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
