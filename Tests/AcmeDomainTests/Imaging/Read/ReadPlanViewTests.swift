@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadPlan("code-582", title: "title-745")
        let view = Imaging.toReadPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadPlanViews([item, item]).count == 2)
    }
}
