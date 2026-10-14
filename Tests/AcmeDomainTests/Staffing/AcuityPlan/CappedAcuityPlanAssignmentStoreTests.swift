@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryCappedAcuityPlanAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.CappedAcuityPlanAssignmentStore = Staffing.newMemoryCappedAcuityPlanAssignmentStore()
        let item = Staffing.newCappedAcuityPlanAssignment("code-163", title: "title-325")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
