@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryWeightedCredentialPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.WeightedCredentialPlanStore = Staffing.newMemoryWeightedCredentialPlanStore()
        let item = Staffing.newWeightedCredentialPlan("code-931", name: "name-370")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
