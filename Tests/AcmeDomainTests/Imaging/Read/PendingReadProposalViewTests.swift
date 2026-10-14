@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingReadProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPendingReadProposal("code-392", label: "label-981")
        let view = Imaging.toPendingReadProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPendingReadProposalViews([item, item]).count == 2)
    }
}
