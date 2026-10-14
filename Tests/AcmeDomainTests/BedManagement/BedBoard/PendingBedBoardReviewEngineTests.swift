@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingBedBoardReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPendingBedBoardReviewEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newPendingBedBoardReview("code-26", label: "label-578")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
