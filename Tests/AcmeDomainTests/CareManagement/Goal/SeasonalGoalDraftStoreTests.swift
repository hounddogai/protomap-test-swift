@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemorySeasonalGoalDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.SeasonalGoalDraftStore = CareManagement.newMemorySeasonalGoalDraftStore()
        let item = CareManagement.newSeasonalGoalDraft("code-736", label: "label-937")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
