@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeManifestStore = RevenueCycle.newMemoryChargeManifestStore()
        let item = RevenueCycle.newChargeManifest("code-784", title: "title-530")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
