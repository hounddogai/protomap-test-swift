@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRollingStatementGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RollingStatementGroupStore = RevenueCycle.newMemoryRollingStatementGroupStore()
        let item = RevenueCycle.newRollingStatementGroup("code-466", title: "title-299")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
