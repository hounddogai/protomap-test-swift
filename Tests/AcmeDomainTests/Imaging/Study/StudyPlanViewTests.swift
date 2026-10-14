@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStudyPlan("code-204", name: "name-397")
        let view = Imaging.toStudyPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStudyPlanViews([item, item]).count == 2)
    }
}
