@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLegacyDisclosureBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LegacyDisclosureBaselineStore = Consent.newMemoryLegacyDisclosureBaselineStore()
        let item = Consent.newLegacyDisclosureBaseline("code-143", name: "name-542")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
