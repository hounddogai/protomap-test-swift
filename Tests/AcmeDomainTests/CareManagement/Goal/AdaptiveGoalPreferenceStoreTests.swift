@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveGoalPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveGoalPreferenceStore = CareManagement.newMemoryAdaptiveGoalPreferenceStore()
        let item = CareManagement.newAdaptiveGoalPreference("code-227", label: "label-301")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
