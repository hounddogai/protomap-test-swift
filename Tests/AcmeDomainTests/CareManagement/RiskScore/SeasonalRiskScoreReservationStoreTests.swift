@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemorySeasonalRiskScoreReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.SeasonalRiskScoreReservationStore = CareManagement.newMemorySeasonalRiskScoreReservationStore()
        let item = CareManagement.newSeasonalRiskScoreReservation("code-604", label: "label-551")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
