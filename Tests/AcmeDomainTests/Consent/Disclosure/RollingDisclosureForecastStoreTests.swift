@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingDisclosureForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingDisclosureForecastStore = Consent.newMemoryRollingDisclosureForecastStore()
        let item = Consent.newRollingDisclosureForecast("code-895", title: "title-925")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
