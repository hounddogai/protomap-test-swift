@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryScheduledChargeDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ScheduledChargeDigestStore = RevenueCycle.newMemoryScheduledChargeDigestStore()
        let item = RevenueCycle.newScheduledChargeDigest("code-177", name: "name-261")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
