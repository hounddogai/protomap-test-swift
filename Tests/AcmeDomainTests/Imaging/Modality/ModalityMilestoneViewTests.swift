@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newModalityMilestone("code-850", label: "label-258")
        let view = Imaging.toModalityMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toModalityMilestoneViews([item, item]).count == 2)
    }
}
