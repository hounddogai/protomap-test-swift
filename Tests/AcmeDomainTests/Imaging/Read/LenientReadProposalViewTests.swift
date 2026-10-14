@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientReadProposal("code-677", title: "title-633")
        let view = Imaging.toLenientReadProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientReadProposalViews([item, item]).count == 2)
    }
}
