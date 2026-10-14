@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedProgramDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedProgramDraftStore = CareManagement.newMemoryBatchedProgramDraftStore()
        let item = CareManagement.newBatchedProgramDraft("code-796", title: "title-171")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
