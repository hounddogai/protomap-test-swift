@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryScheduledDenialBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ScheduledDenialBaselineStore = RevenueCycle.newMemoryScheduledDenialBaselineStore()
        let item = RevenueCycle.newScheduledDenialBaseline("code-642", name: "name-81")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
