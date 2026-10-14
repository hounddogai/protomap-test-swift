@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultRemittanceDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultRemittanceDigestStore = RevenueCycle.newMemoryDefaultRemittanceDigestStore()
        let item = RevenueCycle.newDefaultRemittanceDigest("code-400", name: "name-507")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
