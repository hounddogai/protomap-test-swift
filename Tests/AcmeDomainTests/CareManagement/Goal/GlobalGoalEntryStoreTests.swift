@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalGoalEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalGoalEntryStore = CareManagement.newMemoryGlobalGoalEntryStore()
        let item = CareManagement.newGlobalGoalEntry("code-936", label: "label-39")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
