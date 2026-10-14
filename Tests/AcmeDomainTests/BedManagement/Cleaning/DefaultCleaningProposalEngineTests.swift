@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDefaultCleaningProposalEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newDefaultCleaningProposal("code-114", name: "name-26")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
