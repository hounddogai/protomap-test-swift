@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledWorklistAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledWorklistAdjustment("code-706", label: "label-640")
        let view = Imaging.toScheduledWorklistAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledWorklistAdjustmentViews([item, item]).count == 2)
    }
}
