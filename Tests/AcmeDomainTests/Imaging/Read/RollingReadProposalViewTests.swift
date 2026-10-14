@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingReadProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingReadProposal("code-911", title: "title-261")
        let view = Imaging.toRollingReadProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingReadProposalViews([item, item]).count == 2)
    }
}
