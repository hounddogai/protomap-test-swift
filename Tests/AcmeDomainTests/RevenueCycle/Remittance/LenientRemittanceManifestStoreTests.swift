@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientRemittanceManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientRemittanceManifestStore = RevenueCycle.newMemoryLenientRemittanceManifestStore()
        let item = RevenueCycle.newLenientRemittanceManifest("code-266", name: "name-980")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
