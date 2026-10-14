@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryBatchedOvertimeEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.BatchedOvertimeEntryStore = Staffing.newMemoryBatchedOvertimeEntryStore()
        let item = Staffing.newBatchedOvertimeEntry("code-272", title: "title-482")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
