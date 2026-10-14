@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentReviewStore = CareManagement.newMemoryAssessmentReviewStore()
        let item = CareManagement.newAssessmentReview("code-922", title: "title-998")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
