@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessForecastStore = Consent.newMemoryWitnessForecastStore()
        let item = Consent.newWitnessForecast("code-505", label: "label-2")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
