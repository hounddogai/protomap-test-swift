@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedWorklistTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWeightedWorklistTemplate("code-466", title: "title-357")
        let view = Imaging.toWeightedWorklistTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWeightedWorklistTemplateViews([item, item]).count == 2)
    }
}
