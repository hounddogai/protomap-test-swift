@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientWorklistTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newLenientWorklistTemplate("code-882", label: "label-821")
        let view = Imaging.toLenientWorklistTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toLenientWorklistTemplateViews([item, item]).count == 2)
    }
}
