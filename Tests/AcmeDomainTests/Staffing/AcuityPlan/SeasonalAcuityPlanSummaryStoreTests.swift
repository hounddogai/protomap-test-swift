@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySeasonalAcuityPlanSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SeasonalAcuityPlanSummaryStore = Staffing.newMemorySeasonalAcuityPlanSummaryStore()
        let item = Staffing.newSeasonalAcuityPlanSummary("code-961", name: "name-924")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
