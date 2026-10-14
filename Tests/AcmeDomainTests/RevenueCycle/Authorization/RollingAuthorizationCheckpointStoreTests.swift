@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRollingAuthorizationCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RollingAuthorizationCheckpointStore = RevenueCycle.newMemoryRollingAuthorizationCheckpointStore()
        let item = RevenueCycle.newRollingAuthorizationCheckpoint("code-515", name: "name-873")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
