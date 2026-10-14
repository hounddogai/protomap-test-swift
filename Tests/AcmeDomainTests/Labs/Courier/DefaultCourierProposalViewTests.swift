@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultCourierProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newDefaultCourierProposal("code-758", name: "name-27")
        let view = Labs.toDefaultCourierProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toDefaultCourierProposalViews([item, item]).count == 2)
    }
}
