@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationBaselineStore = RevenueCycle.newMemoryAuthorizationBaselineStore()
        let item = RevenueCycle.newAuthorizationBaseline("code-354", label: "label-685")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
