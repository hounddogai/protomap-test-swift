@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalDenialMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalDenialMilestoneStore = RevenueCycle.newMemoryGlobalDenialMilestoneStore()
        let item = RevenueCycle.newGlobalDenialMilestone("code-428", name: "name-717")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
