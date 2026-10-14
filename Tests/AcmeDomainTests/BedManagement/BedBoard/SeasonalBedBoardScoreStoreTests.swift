@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemorySeasonalBedBoardScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.SeasonalBedBoardScoreStore = BedManagement.newMemorySeasonalBedBoardScoreStore()
        let item = BedManagement.newSeasonalBedBoardScore("code-322", title: "title-756")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
