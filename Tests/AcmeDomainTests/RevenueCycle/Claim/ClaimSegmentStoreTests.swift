@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimSegmentStore = RevenueCycle.newMemoryClaimSegmentStore()
        let item = RevenueCycle.newClaimSegment("code-915", label: "label-232")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
