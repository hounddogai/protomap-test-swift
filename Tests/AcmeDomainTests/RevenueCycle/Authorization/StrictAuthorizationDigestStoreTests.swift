@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictAuthorizationDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictAuthorizationDigestStore = RevenueCycle.newMemoryStrictAuthorizationDigestStore()
        let item = RevenueCycle.newStrictAuthorizationDigest("code-365", name: "name-956")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
