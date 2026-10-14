@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyEstimateStore = Consent.newMemoryProxyEstimateStore()
        let item = Consent.newProxyEstimate("code-808", label: "label-86")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
