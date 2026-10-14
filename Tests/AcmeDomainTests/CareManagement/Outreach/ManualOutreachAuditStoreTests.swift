@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualOutreachAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualOutreachAuditStore = CareManagement.newMemoryManualOutreachAuditStore()
        let item = CareManagement.newManualOutreachAudit("code-288", label: "label-377")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
