@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanPolicyStore = Staffing.newMemoryAcuityPlanPolicyStore()
        let item = Staffing.newAcuityPlanPolicy("code-421", label: "label-651")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
