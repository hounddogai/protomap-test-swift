@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictDenialManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictDenialManifestStore = RevenueCycle.newMemoryStrictDenialManifestStore()
        let item = RevenueCycle.newStrictDenialManifest("code-97", title: "title-173")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
