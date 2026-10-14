@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimaryInventoryPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimaryInventoryPlanStore = Pharmacy.newMemoryPrimaryInventoryPlanStore()
        let item = Pharmacy.newPrimaryInventoryPlan("code-835", title: "title-659")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
