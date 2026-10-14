@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachAuditStore = CareManagement.newMemoryOutreachAuditStore()
        let item = CareManagement.newOutreachAudit("code-861", name: "name-43")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
