@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimManifestStore = RevenueCycle.newMemoryClaimManifestStore()
        let item = RevenueCycle.newClaimManifest("code-509", name: "name-571")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
