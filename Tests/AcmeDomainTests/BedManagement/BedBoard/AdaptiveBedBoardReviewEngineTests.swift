@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultAdaptiveBedBoardReviewEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newAdaptiveBedBoardReview("code-328", name: "name-628")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
