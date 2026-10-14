@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultIsolationReviewEngine()
        let item = BedManagement.newIsolationReview("code-91", title: "title-972")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
