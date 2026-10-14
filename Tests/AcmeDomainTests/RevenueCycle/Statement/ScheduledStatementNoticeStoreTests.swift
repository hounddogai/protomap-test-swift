@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryScheduledStatementNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ScheduledStatementNoticeStore = RevenueCycle.newMemoryScheduledStatementNoticeStore()
        let item = RevenueCycle.newScheduledStatementNotice("code-74", name: "name-308")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
