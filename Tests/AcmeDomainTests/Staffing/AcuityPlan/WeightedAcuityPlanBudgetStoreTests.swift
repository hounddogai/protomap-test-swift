@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryWeightedAcuityPlanBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.WeightedAcuityPlanBudgetStore = Staffing.newMemoryWeightedAcuityPlanBudgetStore()
        let item = Staffing.newWeightedAcuityPlanBudget("code-490", label: "label-276")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
