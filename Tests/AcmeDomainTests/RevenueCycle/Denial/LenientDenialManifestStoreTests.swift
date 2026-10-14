@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientDenialManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientDenialManifestStore = RevenueCycle.newMemoryLenientDenialManifestStore()
        let item = RevenueCycle.newLenientDenialManifest("code-106", label: "label-199")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
