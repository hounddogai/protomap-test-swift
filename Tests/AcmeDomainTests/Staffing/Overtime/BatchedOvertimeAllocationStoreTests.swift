@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryBatchedOvertimeAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.BatchedOvertimeAllocationStore = Staffing.newMemoryBatchedOvertimeAllocationStore()
        let item = Staffing.newBatchedOvertimeAllocation("code-726", title: "title-414")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
