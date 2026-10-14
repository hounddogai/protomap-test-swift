@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialDigestStore = RevenueCycle.newMemoryDenialDigestStore()
        let item = RevenueCycle.newDenialDigest("code-587", title: "title-759")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
