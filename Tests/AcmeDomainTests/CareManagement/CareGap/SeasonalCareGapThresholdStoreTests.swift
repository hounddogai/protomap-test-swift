@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemorySeasonalCareGapThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.SeasonalCareGapThresholdStore = CareManagement.newMemorySeasonalCareGapThresholdStore()
        let item = CareManagement.newSeasonalCareGapThreshold("code-720", name: "name-729")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
