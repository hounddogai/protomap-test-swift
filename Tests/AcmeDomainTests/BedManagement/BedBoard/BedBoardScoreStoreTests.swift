@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardScoreStore = BedManagement.newMemoryBedBoardScoreStore()
        let item = BedManagement.newBedBoardScore("code-99", title: "title-120")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
