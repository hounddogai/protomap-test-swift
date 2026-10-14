@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramPlanStore = CareManagement.newMemoryProgramPlanStore()
        let item = CareManagement.newProgramPlan("code-595", title: "title-500")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
