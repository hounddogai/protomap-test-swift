@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyAccessionProposal("code-626", name: "name-323")
        let view = Labs.toLegacyAccessionProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyAccessionProposalViews([item, item]).count == 2)
    }
}
