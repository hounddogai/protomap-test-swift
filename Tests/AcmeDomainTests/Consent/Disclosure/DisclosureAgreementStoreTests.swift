@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureAgreementStore = Consent.newMemoryDisclosureAgreementStore()
        let item = Consent.newDisclosureAgreement("code-825", title: "title-129")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
