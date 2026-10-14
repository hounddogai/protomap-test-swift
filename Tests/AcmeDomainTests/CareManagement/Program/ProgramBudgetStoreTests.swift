@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramBudgetStore = CareManagement.newMemoryProgramBudgetStore()
        let item = CareManagement.newProgramBudget("code-713", title: "title-544")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
