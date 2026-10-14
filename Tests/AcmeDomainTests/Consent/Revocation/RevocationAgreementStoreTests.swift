@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationAgreementStore = Consent.newMemoryRevocationAgreementStore()
        let item = Consent.newRevocationAgreement("code-273", label: "label-170")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
