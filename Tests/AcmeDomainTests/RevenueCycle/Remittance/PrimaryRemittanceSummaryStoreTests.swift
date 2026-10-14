@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPrimaryRemittanceSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PrimaryRemittanceSummaryStore = RevenueCycle.newMemoryPrimaryRemittanceSummaryStore()
        let item = RevenueCycle.newPrimaryRemittanceSummary("code-261", label: "label-113")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
