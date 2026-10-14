@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLenientLanguageAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LenientLanguageAgreementStore = Consent.newMemoryLenientLanguageAgreementStore()
        let item = Consent.newLenientLanguageAgreement("code-857", title: "title-49")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
