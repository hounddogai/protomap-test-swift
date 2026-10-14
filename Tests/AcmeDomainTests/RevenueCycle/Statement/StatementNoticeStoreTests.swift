@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementNoticeStore = RevenueCycle.newMemoryStatementNoticeStore()
        let item = RevenueCycle.newStatementNotice("code-978", name: "name-780")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
