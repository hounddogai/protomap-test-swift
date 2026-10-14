@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFallbackFormularyAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FallbackFormularyAgreementStore = Pharmacy.newMemoryFallbackFormularyAgreementStore()
        let item = Pharmacy.newFallbackFormularyAgreement("code-953", label: "label-624")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
