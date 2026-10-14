@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultTransferProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDefaultTransferProposalEngine()
        let item = BedManagement.newDefaultTransferProposal("code-402", label: "label-118")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
