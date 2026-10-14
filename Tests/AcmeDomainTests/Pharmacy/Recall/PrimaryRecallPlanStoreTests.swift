@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimaryRecallPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimaryRecallPlanStore = Pharmacy.newMemoryPrimaryRecallPlanStore()
        let item = Pharmacy.newPrimaryRecallPlan("code-599", label: "label-561")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
