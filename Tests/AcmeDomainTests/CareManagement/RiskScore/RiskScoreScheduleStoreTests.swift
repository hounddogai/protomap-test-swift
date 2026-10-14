@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreScheduleStore = CareManagement.newMemoryRiskScoreScheduleStore()
        let item = CareManagement.newRiskScoreSchedule("code-26", name: "name-311")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
