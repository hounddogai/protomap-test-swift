@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceMilestoneStore = RevenueCycle.newMemoryRemittanceMilestoneStore()
        let item = RevenueCycle.newRemittanceMilestone("code-500", title: "title-970")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
