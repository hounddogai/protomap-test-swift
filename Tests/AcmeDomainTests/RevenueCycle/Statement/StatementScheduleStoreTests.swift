@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementScheduleStore = RevenueCycle.newMemoryStatementScheduleStore()
        let item = RevenueCycle.newStatementSchedule("code-461", label: "label-364")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
