@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanRollupStore = Staffing.newMemoryAcuityPlanRollupStore()
        let item = Staffing.newAcuityPlanRollup("code-788", title: "title-380")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
