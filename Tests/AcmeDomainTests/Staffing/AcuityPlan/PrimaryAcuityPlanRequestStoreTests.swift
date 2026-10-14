@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryAcuityPlanRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryAcuityPlanRequestStore = Staffing.newMemoryPrimaryAcuityPlanRequestStore()
        let item = Staffing.newPrimaryAcuityPlanRequest("code-136", name: "name-400")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
