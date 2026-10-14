@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualGoalSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualGoalSummaryStore = CareManagement.newMemoryManualGoalSummaryStore()
        let item = CareManagement.newManualGoalSummary("code-713", label: "label-565")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
