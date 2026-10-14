@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyMetricStore = Consent.newMemoryProxyMetricStore()
        let item = Consent.newProxyMetric("code-768", name: "name-985")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
