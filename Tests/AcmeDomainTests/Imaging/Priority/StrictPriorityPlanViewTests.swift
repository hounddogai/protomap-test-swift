@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictPriorityPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStrictPriorityPlan("code-170", title: "title-256")
        let view = Imaging.toStrictPriorityPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStrictPriorityPlanViews([item, item]).count == 2)
    }
}
