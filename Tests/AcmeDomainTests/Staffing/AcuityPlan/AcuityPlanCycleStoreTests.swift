@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanCycleStore = Staffing.newMemoryAcuityPlanCycleStore()
        let item = Staffing.newAcuityPlanCycle("code-596", name: "name-311")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
