@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPendingOvertimeReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PendingOvertimeReservationStore = Staffing.newMemoryPendingOvertimeReservationStore()
        let item = Staffing.newPendingOvertimeReservation("code-551", title: "title-77")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
