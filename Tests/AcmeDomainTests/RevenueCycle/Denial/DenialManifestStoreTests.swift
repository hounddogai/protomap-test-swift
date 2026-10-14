@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialManifestStore = RevenueCycle.newMemoryDenialManifestStore()
        let item = RevenueCycle.newDenialManifest("code-680", name: "name-175")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
