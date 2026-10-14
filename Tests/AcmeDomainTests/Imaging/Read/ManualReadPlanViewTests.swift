@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualReadPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newManualReadPlan("code-524", name: "name-775")
        let view = Imaging.toManualReadPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toManualReadPlanViews([item, item]).count == 2)
    }
}
