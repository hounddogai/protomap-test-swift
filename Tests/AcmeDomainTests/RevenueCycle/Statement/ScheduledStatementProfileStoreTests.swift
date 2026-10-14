@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryScheduledStatementProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ScheduledStatementProfileStore = RevenueCycle.newMemoryScheduledStatementProfileStore()
        let item = RevenueCycle.newScheduledStatementProfile("code-326", name: "name-763")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
