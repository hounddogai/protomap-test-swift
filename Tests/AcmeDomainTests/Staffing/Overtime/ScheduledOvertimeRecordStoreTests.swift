@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryScheduledOvertimeRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ScheduledOvertimeRecordStore = Staffing.newMemoryScheduledOvertimeRecordStore()
        let item = Staffing.newScheduledOvertimeRecord("code-971", label: "label-899")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
