@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyAdjustmentStore = Consent.newMemoryProxyAdjustmentStore()
        let item = Consent.newProxyAdjustment("code-949", label: "label-891")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
