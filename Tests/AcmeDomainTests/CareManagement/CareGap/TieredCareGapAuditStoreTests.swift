@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredCareGapAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredCareGapAuditStore = CareManagement.newMemoryTieredCareGapAuditStore()
        let item = CareManagement.newTieredCareGapAudit("code-548", title: "title-639")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
