@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalTemplateStore = CareManagement.newMemoryGoalTemplateStore()
        let item = CareManagement.newGoalTemplate("code-842", title: "title-544")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
