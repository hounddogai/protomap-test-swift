@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedModalityProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedModalityProposal("code-108", name: "name-645")
        let view = Imaging.toWeightedModalityProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedModalityProposalViews([item, item]).count == 2)
    }
}
