@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadMilestone("code-469", name: "name-117")
        let view = Imaging.toReadMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadMilestoneViews([item, item]).count == 2)
    }
}
