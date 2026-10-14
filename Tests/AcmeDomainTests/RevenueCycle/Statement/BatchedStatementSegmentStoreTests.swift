@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedStatementSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedStatementSegmentStore = RevenueCycle.newMemoryBatchedStatementSegmentStore()
        let item = RevenueCycle.newBatchedStatementSegment("code-521", name: "name-198")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
