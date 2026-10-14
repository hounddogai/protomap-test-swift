@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingOutreachReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingOutreachReservationStore = CareManagement.newMemoryRollingOutreachReservationStore()
        let item = CareManagement.newRollingOutreachReservation("code-720", label: "label-588")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
