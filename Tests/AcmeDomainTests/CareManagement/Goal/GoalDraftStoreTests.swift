@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalDraftStore = CareManagement.newMemoryGoalDraftStore()
        let item = CareManagement.newGoalDraft("code-118", label: "label-627")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
