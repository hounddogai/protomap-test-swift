@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationSummaryStore = RevenueCycle.newMemoryAuthorizationSummaryStore()
        let item = RevenueCycle.newAuthorizationSummary("code-247", title: "title-780")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
