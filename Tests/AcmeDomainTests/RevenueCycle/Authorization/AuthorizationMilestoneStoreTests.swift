@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationMilestoneStore = RevenueCycle.newMemoryAuthorizationMilestoneStore()
        let item = RevenueCycle.newAuthorizationMilestone("code-998", title: "title-366")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
