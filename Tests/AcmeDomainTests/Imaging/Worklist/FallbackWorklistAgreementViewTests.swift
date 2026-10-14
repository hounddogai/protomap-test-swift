@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackWorklistAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackWorklistAgreement("code-273", title: "title-452")
        let view = Imaging.toFallbackWorklistAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackWorklistAgreementViews([item, item]).count == 2)
    }
}
