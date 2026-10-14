@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyAuthorizationSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyAuthorizationSegmentStore = RevenueCycle.newMemoryLegacyAuthorizationSegmentStore()
        let item = RevenueCycle.newLegacyAuthorizationSegment("code-727", title: "title-232")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
