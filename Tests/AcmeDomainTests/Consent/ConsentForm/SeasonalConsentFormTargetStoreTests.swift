@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemorySeasonalConsentFormTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.SeasonalConsentFormTargetStore = Consent.newMemorySeasonalConsentFormTargetStore()
        let item = Consent.newSeasonalConsentFormTarget("code-353", name: "name-435")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
