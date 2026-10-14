@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryTransferAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPrimaryTransferAssignmentEngine()
        let item = BedManagement.newPrimaryTransferAssignment("code-153", name: "name-45")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
