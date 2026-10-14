@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingLanguageForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingLanguageForecastStore = Consent.newMemoryRollingLanguageForecastStore()
        let item = Consent.newRollingLanguageForecast("code-785", label: "label-800")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
