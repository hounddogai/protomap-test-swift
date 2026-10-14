@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientInventoryPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientInventoryPlanStore = Pharmacy.newMemoryLenientInventoryPlanStore()
        let item = Pharmacy.newLenientInventoryPlan("code-742", label: "label-309")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
