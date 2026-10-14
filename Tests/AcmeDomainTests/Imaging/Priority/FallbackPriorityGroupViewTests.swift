@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackPriorityGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackPriorityGroup("code-553", label: "label-687")
        let view = Imaging.toFallbackPriorityGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackPriorityGroupViews([item, item]).count == 2)
    }
}
