@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanAuditStore = BedManagement.newMemoryDischargePlanAuditStore()
        let item = BedManagement.newDischargePlanAudit("code-538", title: "title-357")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
