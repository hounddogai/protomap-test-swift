@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingDisclosureAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingDisclosureAgreementStore = Consent.newMemoryRollingDisclosureAgreementStore()
        let item = Consent.newRollingDisclosureAgreement("code-294", title: "title-311")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
