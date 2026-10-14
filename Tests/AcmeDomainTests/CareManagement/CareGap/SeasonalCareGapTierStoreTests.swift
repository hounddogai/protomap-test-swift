@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemorySeasonalCareGapTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.SeasonalCareGapTierStore = CareManagement.newMemorySeasonalCareGapTierStore()
        let item = CareManagement.newSeasonalCareGapTier("code-904", name: "name-592")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
