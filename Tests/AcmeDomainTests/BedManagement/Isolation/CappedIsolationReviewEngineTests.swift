@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCappedIsolationReviewEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCappedIsolationReview("code-764", name: "name-966")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
