@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramSummaryStore = CareManagement.newMemoryProgramSummaryStore()
        let item = CareManagement.newProgramSummary("code-362", title: "title-796")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
