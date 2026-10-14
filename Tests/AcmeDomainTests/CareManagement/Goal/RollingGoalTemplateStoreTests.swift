@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingGoalTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingGoalTemplateStore = CareManagement.newMemoryRollingGoalTemplateStore()
        let item = CareManagement.newRollingGoalTemplate("code-798", label: "label-668")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
