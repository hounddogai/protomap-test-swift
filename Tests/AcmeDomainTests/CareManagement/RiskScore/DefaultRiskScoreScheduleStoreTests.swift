@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultRiskScoreScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultRiskScoreScheduleStore = CareManagement.newMemoryDefaultRiskScoreScheduleStore()
        let item = CareManagement.newDefaultRiskScoreSchedule("code-555", name: "name-379")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
