@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyAgreementStore = Pharmacy.newMemoryFormularyAgreementStore()
        let item = Pharmacy.newFormularyAgreement("code-474", title: "title-591")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
