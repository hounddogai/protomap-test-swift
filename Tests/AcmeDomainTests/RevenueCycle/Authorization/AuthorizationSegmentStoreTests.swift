@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationSegmentStore = RevenueCycle.newMemoryAuthorizationSegmentStore()
        let item = RevenueCycle.newAuthorizationSegment("code-220", name: "name-436")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
