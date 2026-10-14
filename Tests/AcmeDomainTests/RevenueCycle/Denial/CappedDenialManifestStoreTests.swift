@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryCappedDenialManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.CappedDenialManifestStore = RevenueCycle.newMemoryCappedDenialManifestStore()
        let item = RevenueCycle.newCappedDenialManifest("code-750", label: "label-232")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
