@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyResultProposal("code-508", title: "title-138")
        let view = Labs.toLegacyResultProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyResultProposalViews([item, item]).count == 2)
    }
}
