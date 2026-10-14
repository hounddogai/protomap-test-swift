@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRollingAcuityPlanAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RollingAcuityPlanAssignmentStore = Staffing.newMemoryRollingAcuityPlanAssignmentStore()
        let item = Staffing.newRollingAcuityPlanAssignment("code-918", name: "name-634")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
