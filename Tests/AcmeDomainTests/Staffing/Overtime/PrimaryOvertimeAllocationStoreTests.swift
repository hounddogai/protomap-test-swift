@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryOvertimeAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryOvertimeAllocationStore = Staffing.newMemoryPrimaryOvertimeAllocationStore()
        let item = Staffing.newPrimaryOvertimeAllocation("code-192", title: "title-199")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
