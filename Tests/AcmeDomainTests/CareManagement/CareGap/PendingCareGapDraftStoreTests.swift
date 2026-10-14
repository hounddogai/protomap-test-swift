@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingCareGapDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingCareGapDraftStore = CareManagement.newMemoryPendingCareGapDraftStore()
        let item = CareManagement.newPendingCareGapDraft("code-588", name: "name-369")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
