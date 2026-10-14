@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingAssessmentReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingAssessmentReservationStore = CareManagement.newMemoryRollingAssessmentReservationStore()
        let item = CareManagement.newRollingAssessmentReservation("code-70", name: "name-440")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
