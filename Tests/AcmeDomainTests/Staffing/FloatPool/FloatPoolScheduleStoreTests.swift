@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolScheduleStore = Staffing.newMemoryFloatPoolScheduleStore()
        let item = Staffing.newFloatPoolSchedule("code-403", name: "name-385")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
