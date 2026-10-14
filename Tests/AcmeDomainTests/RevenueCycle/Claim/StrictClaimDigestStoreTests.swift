@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictClaimDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictClaimDigestStore = RevenueCycle.newMemoryStrictClaimDigestStore()
        let item = RevenueCycle.newStrictClaimDigest("code-630", name: "name-755")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
