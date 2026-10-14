@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierProposal("code-402", name: "name-557")
        let view = Labs.toCourierProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierProposalViews([item, item]).count == 2)
    }
}
