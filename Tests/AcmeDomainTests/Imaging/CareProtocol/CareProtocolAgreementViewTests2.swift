@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newCareProtocolAgreement("code-174", title: "title-404")
        let view = Imaging.toCareProtocolAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toCareProtocolAgreementViews([item, item]).count == 2)
    }
}
