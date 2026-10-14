@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceSummaryStore = RevenueCycle.newMemoryRemittanceSummaryStore()
        let item = RevenueCycle.newRemittanceSummary("code-810", label: "label-312")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
