@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeSegmentStore = Staffing.newMemoryOvertimeSegmentStore()
        let item = Staffing.newOvertimeSegment("code-553", name: "name-527")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
