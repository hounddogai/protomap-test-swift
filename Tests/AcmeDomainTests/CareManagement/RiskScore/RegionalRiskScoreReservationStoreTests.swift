@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRegionalRiskScoreReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RegionalRiskScoreReservationStore = CareManagement.newMemoryRegionalRiskScoreReservationStore()
        let item = CareManagement.newRegionalRiskScoreReservation("code-972", name: "name-458")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
