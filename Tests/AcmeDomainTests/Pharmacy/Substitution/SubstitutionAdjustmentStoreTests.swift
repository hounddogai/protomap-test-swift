@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionAdjustmentStore = Pharmacy.newMemorySubstitutionAdjustmentStore()
        let item = Pharmacy.newSubstitutionAdjustment("code-702", label: "label-946")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
