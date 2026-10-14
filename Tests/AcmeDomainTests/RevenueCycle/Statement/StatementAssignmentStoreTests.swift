@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementAssignmentStore = RevenueCycle.newMemoryStatementAssignmentStore()
        let item = RevenueCycle.newStatementAssignment("code-873", label: "label-768")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
