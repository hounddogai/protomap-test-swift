@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledCareGapReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledCareGapReviewStore = CareManagement.newMemoryScheduledCareGapReviewStore()
        let item = CareManagement.newScheduledCareGapReview("code-241", label: "label-605")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
