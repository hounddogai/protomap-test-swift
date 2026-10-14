@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedReadProposal("code-118", label: "label-665")
        let view = Imaging.toWeightedReadProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedReadProposalViews([item, item]).count == 2)
    }
}
