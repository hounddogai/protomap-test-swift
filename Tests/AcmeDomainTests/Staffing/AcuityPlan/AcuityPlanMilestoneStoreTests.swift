@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanMilestoneStore = Staffing.newMemoryAcuityPlanMilestoneStore()
        let item = Staffing.newAcuityPlanMilestone("code-871", label: "label-474")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
