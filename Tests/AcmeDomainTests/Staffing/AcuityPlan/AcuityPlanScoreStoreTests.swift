@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAcuityPlanScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AcuityPlanScoreStore = Staffing.newMemoryAcuityPlanScoreStore()
        let item = Staffing.newAcuityPlanScore("code-989", name: "name-136")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
