@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardReviewStore = BedManagement.newMemoryBedBoardReviewStore()
        let item = BedManagement.newBedBoardReview("code-505", name: "name-521")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
