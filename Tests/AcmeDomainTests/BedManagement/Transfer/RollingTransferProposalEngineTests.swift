@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingTransferProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultRollingTransferProposalEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newRollingTransferProposal("code-379", title: "title-539")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
