@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallAgreementStore = Pharmacy.newMemoryRecallAgreementStore()
        let item = Pharmacy.newRecallAgreement("code-928", name: "name-383")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
