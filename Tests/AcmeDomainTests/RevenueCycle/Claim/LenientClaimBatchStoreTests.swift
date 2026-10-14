@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientClaimBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientClaimBatchStore = RevenueCycle.newMemoryLenientClaimBatchStore()
        let item = RevenueCycle.newLenientClaimBatch("code-934", title: "title-950")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
