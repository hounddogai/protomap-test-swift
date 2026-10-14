@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemorySeasonalCareGapEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.SeasonalCareGapEntryStore = CareManagement.newMemorySeasonalCareGapEntryStore()
        let item = CareManagement.newSeasonalCareGapEntry("code-689", title: "title-232")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
