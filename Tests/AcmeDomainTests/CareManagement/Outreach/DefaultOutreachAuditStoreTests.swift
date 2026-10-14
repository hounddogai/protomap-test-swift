@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultOutreachAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultOutreachAuditStore = CareManagement.newMemoryDefaultOutreachAuditStore()
        let item = CareManagement.newDefaultOutreachAudit("code-589", title: "title-818")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
