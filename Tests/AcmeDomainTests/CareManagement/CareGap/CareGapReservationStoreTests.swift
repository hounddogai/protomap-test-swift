@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapReservationStore = CareManagement.newMemoryCareGapReservationStore()
        let item = CareManagement.newCareGapReservation("code-667", name: "name-614")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
