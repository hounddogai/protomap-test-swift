@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryAdaptiveIsolationReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.AdaptiveIsolationReviewStore = BedManagement.newMemoryAdaptiveIsolationReviewStore()
        let item = BedManagement.newAdaptiveIsolationReview("code-264", title: "title-556")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
