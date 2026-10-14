@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyForecastStore = Consent.newMemoryProxyForecastStore()
        let item = Consent.newProxyForecast("code-801", name: "name-980")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
