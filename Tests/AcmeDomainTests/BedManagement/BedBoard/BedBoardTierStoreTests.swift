@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardTierStore = BedManagement.newMemoryBedBoardTierStore()
        let item = BedManagement.newBedBoardTier("code-554", title: "title-202")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
