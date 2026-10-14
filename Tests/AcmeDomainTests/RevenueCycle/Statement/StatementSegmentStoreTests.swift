@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementSegmentStore = RevenueCycle.newMemoryStatementSegmentStore()
        let item = RevenueCycle.newStatementSegment("code-918", title: "title-455")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
