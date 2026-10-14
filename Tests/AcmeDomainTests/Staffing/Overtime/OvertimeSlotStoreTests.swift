@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeSlotStore = Staffing.newMemoryOvertimeSlotStore()
        let item = Staffing.newOvertimeSlot("code-126", name: "name-639")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
