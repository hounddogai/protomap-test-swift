@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusReviewStore = BedManagement.newMemoryCensusReviewStore()
        let item = BedManagement.newCensusReview("code-305", name: "name-707")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
