@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLegacyBedBoardReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LegacyBedBoardReviewStore = BedManagement.newMemoryLegacyBedBoardReviewStore()
        let item = BedManagement.newLegacyBedBoardReview("code-475", name: "name-15")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
