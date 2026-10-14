@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAdaptiveAcuityPlanScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AdaptiveAcuityPlanScoreStore = Staffing.newMemoryAdaptiveAcuityPlanScoreStore()
        let item = Staffing.newAdaptiveAcuityPlanScore("code-829", label: "label-59")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
