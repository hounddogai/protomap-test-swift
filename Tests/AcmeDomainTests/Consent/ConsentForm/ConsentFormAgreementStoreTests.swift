@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormAgreementStore = Consent.newMemoryConsentFormAgreementStore()
        let item = Consent.newConsentFormAgreement("code-923", name: "name-19")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
