@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionPlanStore = Pharmacy.newMemorySubstitutionPlanStore()
        let item = Pharmacy.newSubstitutionPlan("code-929", name: "name-755")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
