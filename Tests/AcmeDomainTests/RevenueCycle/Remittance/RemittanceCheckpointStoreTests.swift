@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceCheckpointStore = RevenueCycle.newMemoryRemittanceCheckpointStore()
        let item = RevenueCycle.newRemittanceCheckpoint("code-24", label: "label-346")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
