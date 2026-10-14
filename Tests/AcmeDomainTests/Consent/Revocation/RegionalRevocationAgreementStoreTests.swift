@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRegionalRevocationAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RegionalRevocationAgreementStore = Consent.newMemoryRegionalRevocationAgreementStore()
        let item = Consent.newRegionalRevocationAgreement("code-823", label: "label-311")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
