@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskDraftStore = ClinicalOps.newMemoryTaskDraftStore()
        let item = ClinicalOps.newTaskDraft("code-572", label: "label-785")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
