@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistMilestone("code-386", title: "title-149")
        let view = Imaging.toWorklistMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistMilestoneViews([item, item]).count == 2)
    }
}
