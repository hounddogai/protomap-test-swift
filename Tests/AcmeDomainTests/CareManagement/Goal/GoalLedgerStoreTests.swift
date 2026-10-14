@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalLedgerStore = CareManagement.newMemoryGoalLedgerStore()
        let item = CareManagement.newGoalLedger("code-73", name: "name-298")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
