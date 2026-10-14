@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictWorklistPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStrictWorklistPlan("code-74", title: "title-960")
        let view = Imaging.toStrictWorklistPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStrictWorklistPlanViews([item, item]).count == 2)
    }
}
