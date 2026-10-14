@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLegacyWitnessTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LegacyWitnessTierStore = Consent.newMemoryLegacyWitnessTierStore()
        let item = Consent.newLegacyWitnessTier("code-908", title: "title-36")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
