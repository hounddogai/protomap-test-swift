@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingOutreachBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingOutreachBaselineStore = CareManagement.newMemoryPendingOutreachBaselineStore()
        let item = CareManagement.newPendingOutreachBaseline("code-705", label: "label-651")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
