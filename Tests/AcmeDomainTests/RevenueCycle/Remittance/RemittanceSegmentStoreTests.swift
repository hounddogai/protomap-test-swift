@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceSegmentStore = RevenueCycle.newMemoryRemittanceSegmentStore()
        let item = RevenueCycle.newRemittanceSegment("code-771", title: "title-741")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
