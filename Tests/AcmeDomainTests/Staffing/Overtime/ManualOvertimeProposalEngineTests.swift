@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultManualOvertimeProposalEngine(Kit.Flags.newRegistry())
        let item = Staffing.newManualOvertimeProposal("code-5", name: "name-232")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
