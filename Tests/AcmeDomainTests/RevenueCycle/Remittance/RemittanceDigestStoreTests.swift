@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceDigestStore = RevenueCycle.newMemoryRemittanceDigestStore()
        let item = RevenueCycle.newRemittanceDigest("code-660", name: "name-80")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
