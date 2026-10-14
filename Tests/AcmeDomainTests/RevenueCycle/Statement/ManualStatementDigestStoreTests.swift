@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualStatementDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualStatementDigestStore = RevenueCycle.newMemoryManualStatementDigestStore()
        let item = RevenueCycle.newManualStatementDigest("code-507", name: "name-142")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
