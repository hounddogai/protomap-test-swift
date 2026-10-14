@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWeightedProxyGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WeightedProxyGroupStore = Consent.newMemoryWeightedProxyGroupStore()
        let item = Consent.newWeightedProxyGroup("code-74", title: "title-444")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
