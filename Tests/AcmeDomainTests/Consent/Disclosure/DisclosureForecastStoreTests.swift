@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureForecastStore = Consent.newMemoryDisclosureForecastStore()
        let item = Consent.newDisclosureForecast("code-311", title: "title-219")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
