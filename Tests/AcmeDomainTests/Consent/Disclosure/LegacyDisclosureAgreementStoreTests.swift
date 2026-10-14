@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLegacyDisclosureAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LegacyDisclosureAgreementStore = Consent.newMemoryLegacyDisclosureAgreementStore()
        let item = Consent.newLegacyDisclosureAgreement("code-873", title: "title-840")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
