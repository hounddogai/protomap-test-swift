@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingPriorityAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingPriorityAgreement("code-755", title: "title-462")
        let view = Imaging.toRollingPriorityAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingPriorityAgreementViews([item, item]).count == 2)
    }
}
