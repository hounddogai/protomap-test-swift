@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialMilestoneStore = RevenueCycle.newMemoryDenialMilestoneStore()
        let item = RevenueCycle.newDenialMilestone("code-345", name: "name-97")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
