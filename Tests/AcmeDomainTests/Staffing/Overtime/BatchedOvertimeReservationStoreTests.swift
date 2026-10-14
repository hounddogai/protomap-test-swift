@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryBatchedOvertimeReservationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.BatchedOvertimeReservationStore = Staffing.newMemoryBatchedOvertimeReservationStore()
        let item = Staffing.newBatchedOvertimeReservation("code-698", title: "title-455")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
