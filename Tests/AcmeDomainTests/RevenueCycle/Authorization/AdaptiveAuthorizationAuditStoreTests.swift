@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveAuthorizationAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveAuthorizationAuditStore = RevenueCycle.newMemoryAdaptiveAuthorizationAuditStore()
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("code-423", title: "title-542")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
