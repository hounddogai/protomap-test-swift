@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapAuditStore = CareManagement.newMemoryCareGapAuditStore()
        let item = CareManagement.newCareGapAudit("code-476", label: "label-342")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
