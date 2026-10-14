@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialSegmentStore = RevenueCycle.newMemoryDenialSegmentStore()
        let item = RevenueCycle.newDenialSegment("code-970", title: "title-183")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
