@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedRemittanceTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedRemittanceTargetStore = RevenueCycle.newMemoryBatchedRemittanceTargetStore()
        let item = RevenueCycle.newBatchedRemittanceTarget("code-120", title: "title-620")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
