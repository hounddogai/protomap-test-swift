@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedDenialTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedDenialTargetStore = RevenueCycle.newMemoryBatchedDenialTargetStore()
        let item = RevenueCycle.newBatchedDenialTarget("code-42", name: "name-739")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
