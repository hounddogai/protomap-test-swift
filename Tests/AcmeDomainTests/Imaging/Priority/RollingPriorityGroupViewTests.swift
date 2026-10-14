@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingPriorityGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingPriorityGroup("code-100", title: "title-523")
        let view = Imaging.toRollingPriorityGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingPriorityGroupViews([item, item]).count == 2)
    }
}
