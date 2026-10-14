@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimQuotaStore = RevenueCycle.newMemoryClaimQuotaStore()
        let item = RevenueCycle.newClaimQuota("code-767", title: "title-310")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
