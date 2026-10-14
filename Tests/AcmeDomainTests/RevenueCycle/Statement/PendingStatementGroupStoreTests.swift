@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingStatementGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingStatementGroupStore = RevenueCycle.newMemoryPendingStatementGroupStore()
        let item = RevenueCycle.newPendingStatementGroup("code-814", title: "title-186")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
