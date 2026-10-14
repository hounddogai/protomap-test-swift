@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newWeightedSpecimenProposal("code-53", title: "title-192")
        let view = Labs.toWeightedSpecimenProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toWeightedSpecimenProposalViews([item, item]).count == 2)
    }
}
