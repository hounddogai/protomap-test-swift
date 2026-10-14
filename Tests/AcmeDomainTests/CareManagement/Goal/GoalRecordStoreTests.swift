@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalRecordStore = CareManagement.newMemoryGoalRecordStore()
        let item = CareManagement.newGoalRecord("code-7", title: "title-128")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
