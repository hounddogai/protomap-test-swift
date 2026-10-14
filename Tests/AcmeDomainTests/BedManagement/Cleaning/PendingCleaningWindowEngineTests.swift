@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCleaningWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPendingCleaningWindowEngine()
        let item = BedManagement.newPendingCleaningWindow("code-292", label: "label-107")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
