@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveGoalBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveGoalBaselineStore = CareManagement.newMemoryAdaptiveGoalBaselineStore()
        let item = CareManagement.newAdaptiveGoalBaseline("code-623", title: "title-146")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
