@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledPriorityMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledPriorityMapping("code-177", title: "title-1")
        let view = Imaging.toScheduledPriorityMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledPriorityMappingViews([item, item]).count == 2)
    }
}
