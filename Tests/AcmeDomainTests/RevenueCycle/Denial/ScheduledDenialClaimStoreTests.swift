@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryScheduledDenialClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ScheduledDenialClaimStore = RevenueCycle.newMemoryScheduledDenialClaimStore()
        let item = RevenueCycle.newScheduledDenialClaim("code-189", name: "name-66")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
