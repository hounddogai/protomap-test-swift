@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientAuthorizationDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientAuthorizationDigestStore = RevenueCycle.newMemoryLenientAuthorizationDigestStore()
        let item = RevenueCycle.newLenientAuthorizationDigest("code-437", label: "label-71")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
