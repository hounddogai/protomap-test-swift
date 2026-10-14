@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeProposal("code-658", title: "title-313")
        let view = Labs.toReferenceRangeProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeProposalViews([item, item]).count == 2)
    }
}
