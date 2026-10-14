@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingSpecimenProposal("code-595", name: "name-678")
        let view = Labs.toRollingSpecimenProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingSpecimenProposalViews([item, item]).count == 2)
    }
}
