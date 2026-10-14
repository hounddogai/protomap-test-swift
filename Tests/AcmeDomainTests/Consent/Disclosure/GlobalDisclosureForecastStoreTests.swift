@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryGlobalDisclosureForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.GlobalDisclosureForecastStore = Consent.newMemoryGlobalDisclosureForecastStore()
        let item = Consent.newGlobalDisclosureForecast("code-466", label: "label-800")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
