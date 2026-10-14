@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCleaningProposalEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCleaningProposal("code-590", label: "label-14")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
