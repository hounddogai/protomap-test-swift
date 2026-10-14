@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionAgreementStore = Pharmacy.newMemoryInteractionAgreementStore()
        let item = Pharmacy.newInteractionAgreement("code-219", label: "label-498")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
