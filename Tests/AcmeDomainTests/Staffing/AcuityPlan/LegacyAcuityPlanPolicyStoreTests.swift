@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLegacyAcuityPlanPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LegacyAcuityPlanPolicyStore = Staffing.newMemoryLegacyAcuityPlanPolicyStore()
        let item = Staffing.newLegacyAcuityPlanPolicy("code-231", label: "label-557")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
