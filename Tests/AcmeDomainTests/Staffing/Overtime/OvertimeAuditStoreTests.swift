@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimeAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimeAuditStore = Staffing.newMemoryOvertimeAuditStore()
        let item = Staffing.newOvertimeAudit("code-811", label: "label-603")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
