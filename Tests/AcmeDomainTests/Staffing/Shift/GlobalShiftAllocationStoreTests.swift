@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryGlobalShiftAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.GlobalShiftAllocationStore = Staffing.newMemoryGlobalShiftAllocationStore()
        let item = Staffing.newGlobalShiftAllocation("code-214", title: "title-48")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
