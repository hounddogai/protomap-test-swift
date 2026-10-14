@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPendingAcuityPlanMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PendingAcuityPlanMilestoneStore = Staffing.newMemoryPendingAcuityPlanMilestoneStore()
        let item = Staffing.newPendingAcuityPlanMilestone("code-211", label: "label-559")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
