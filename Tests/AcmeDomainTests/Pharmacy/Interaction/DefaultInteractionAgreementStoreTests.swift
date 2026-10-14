@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultInteractionAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultInteractionAgreementStore = Pharmacy.newMemoryDefaultInteractionAgreementStore()
        let item = Pharmacy.newDefaultInteractionAgreement("code-808", title: "title-359")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
