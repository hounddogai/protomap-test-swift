@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalStatementEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalStatementEstimateStore = RevenueCycle.newMemoryGlobalStatementEstimateStore()
        let item = RevenueCycle.newGlobalStatementEstimate("code-110", label: "label-694")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
