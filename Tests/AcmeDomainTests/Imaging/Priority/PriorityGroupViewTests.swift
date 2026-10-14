@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newPriorityGroup("code-201", label: "label-439")
        let view = Imaging.toPriorityGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toPriorityGroupViews([item, item]).count == 2)
    }
}
