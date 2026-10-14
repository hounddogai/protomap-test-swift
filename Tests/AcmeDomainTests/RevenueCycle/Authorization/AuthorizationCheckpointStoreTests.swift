@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationCheckpointStore = RevenueCycle.newMemoryAuthorizationCheckpointStore()
        let item = RevenueCycle.newAuthorizationCheckpoint("code-337", title: "title-272")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
