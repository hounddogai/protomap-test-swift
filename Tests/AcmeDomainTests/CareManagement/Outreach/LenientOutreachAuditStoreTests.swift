@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientOutreachAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientOutreachAuditStore = CareManagement.newMemoryLenientOutreachAuditStore()
        let item = CareManagement.newLenientOutreachAudit("code-850", title: "title-360")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
