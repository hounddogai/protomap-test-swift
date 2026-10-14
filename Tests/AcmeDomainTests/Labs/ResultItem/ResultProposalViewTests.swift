@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultProposal("code-870", label: "label-867")
        let view = Labs.toResultProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultProposalViews([item, item]).count == 2)
    }
}
