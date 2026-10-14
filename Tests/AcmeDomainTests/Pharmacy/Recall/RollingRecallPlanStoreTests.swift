@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingRecallPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingRecallPlanStore = Pharmacy.newMemoryRollingRecallPlanStore()
        let item = Pharmacy.newRollingRecallPlan("code-718", name: "name-65")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
