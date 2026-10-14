@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledReadPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledReadPlan("code-259", title: "title-372")
        let view = Imaging.toScheduledReadPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledReadPlanViews([item, item]).count == 2)
    }
}
