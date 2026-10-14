@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictCareProtocolTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newStrictCareProtocolTemplate("code-213", label: "label-534")
        let view = Imaging.toStrictCareProtocolTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toStrictCareProtocolTemplateViews([item, item]).count == 2)
    }
}
