@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCredentialProposalEngine(Kit.Flags.newRegistry())
        let item = Staffing.newCredentialProposal("code-663", title: "title-751")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
