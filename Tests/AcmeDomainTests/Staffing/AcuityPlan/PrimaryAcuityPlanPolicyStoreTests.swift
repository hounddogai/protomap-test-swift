@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryAcuityPlanPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryAcuityPlanPolicyStore = Staffing.newMemoryPrimaryAcuityPlanPolicyStore()
        let item = Staffing.newPrimaryAcuityPlanPolicy("code-870", label: "label-10")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
