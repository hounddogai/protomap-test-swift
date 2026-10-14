@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentReservationStore = CareManagement.newMemoryAssessmentReservationStore()
        let item = CareManagement.newAssessmentReservation("code-193", name: "name-195")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
