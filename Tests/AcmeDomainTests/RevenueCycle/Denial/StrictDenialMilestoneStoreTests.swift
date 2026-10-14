@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictDenialMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictDenialMilestoneStore = RevenueCycle.newMemoryStrictDenialMilestoneStore()
        let item = RevenueCycle.newStrictDenialMilestone("code-301", title: "title-922")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
