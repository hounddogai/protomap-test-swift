@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingStatementTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingStatementTargetStore = RevenueCycle.newMemoryPendingStatementTargetStore()
        let item = RevenueCycle.newPendingStatementTarget("code-24", name: "name-439")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
