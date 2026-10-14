@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftScheduleStore = Staffing.newMemoryShiftScheduleStore()
        let item = Staffing.newShiftSchedule("code-889", label: "label-320")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
