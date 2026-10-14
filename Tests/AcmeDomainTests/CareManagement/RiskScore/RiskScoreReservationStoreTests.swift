@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreReservationStore = CareManagement.newMemoryRiskScoreReservationStore()
        let item = CareManagement.newRiskScoreReservation("code-503", title: "title-472")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
