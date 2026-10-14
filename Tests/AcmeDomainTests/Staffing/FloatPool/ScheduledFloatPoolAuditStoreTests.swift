@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryScheduledFloatPoolAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ScheduledFloatPoolAuditStore = Staffing.newMemoryScheduledFloatPoolAuditStore()
        let item = Staffing.newScheduledFloatPoolAudit("code-898", label: "label-291")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
