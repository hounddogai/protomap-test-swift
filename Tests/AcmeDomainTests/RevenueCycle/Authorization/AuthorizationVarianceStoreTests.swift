@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationVarianceStore = RevenueCycle.newMemoryAuthorizationVarianceStore()
        let item = RevenueCycle.newAuthorizationVariance("code-557", title: "title-427")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
