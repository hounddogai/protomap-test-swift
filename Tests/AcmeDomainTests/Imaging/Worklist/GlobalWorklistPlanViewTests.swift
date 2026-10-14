@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalWorklistPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newGlobalWorklistPlan("code-684", label: "label-835")
        let view = Imaging.toGlobalWorklistPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toGlobalWorklistPlanViews([item, item]).count == 2)
    }
}
