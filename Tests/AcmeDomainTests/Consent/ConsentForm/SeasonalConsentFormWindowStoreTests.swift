@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemorySeasonalConsentFormWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.SeasonalConsentFormWindowStore = Consent.newMemorySeasonalConsentFormWindowStore()
        let item = Consent.newSeasonalConsentFormWindow("code-362", title: "title-429")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
