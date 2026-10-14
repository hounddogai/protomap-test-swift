@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolAuditStore = Staffing.newMemoryFloatPoolAuditStore()
        let item = Staffing.newFloatPoolAudit("code-328", title: "title-385")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
