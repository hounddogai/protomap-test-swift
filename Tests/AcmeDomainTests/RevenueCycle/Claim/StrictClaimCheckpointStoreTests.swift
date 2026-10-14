@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictClaimCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictClaimCheckpointStore = RevenueCycle.newMemoryStrictClaimCheckpointStore()
        let item = RevenueCycle.newStrictClaimCheckpoint("code-474", title: "title-728")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
