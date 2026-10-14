@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryBatchedOvertimePlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.BatchedOvertimePlanStore = Staffing.newMemoryBatchedOvertimePlanStore()
        let item = Staffing.newBatchedOvertimePlan("code-998", name: "name-320")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
