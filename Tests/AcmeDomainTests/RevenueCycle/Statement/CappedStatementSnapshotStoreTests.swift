@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryCappedStatementSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.CappedStatementSnapshotStore = RevenueCycle.newMemoryCappedStatementSnapshotStore()
        let item = RevenueCycle.newCappedStatementSnapshot("code-247", title: "title-878")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
