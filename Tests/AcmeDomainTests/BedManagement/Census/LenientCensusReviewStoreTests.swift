@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLenientCensusReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LenientCensusReviewStore = BedManagement.newMemoryLenientCensusReviewStore()
        let item = BedManagement.newLenientCensusReview("code-297", label: "label-430")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
