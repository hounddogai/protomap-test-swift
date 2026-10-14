@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeMilestoneStore = Staffing.newMemoryOvertimeMilestoneStore()
        let item = Staffing.newOvertimeMilestone("code-264", name: "name-497")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
