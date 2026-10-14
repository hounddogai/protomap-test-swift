@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimDigestStore = RevenueCycle.newMemoryClaimDigestStore()
        let item = RevenueCycle.newClaimDigest("code-453", label: "label-648")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
