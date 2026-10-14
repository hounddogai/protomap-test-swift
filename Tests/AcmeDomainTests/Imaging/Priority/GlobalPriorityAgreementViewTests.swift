@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newGlobalPriorityAgreement("code-89", name: "name-635")
        let view = Imaging.toGlobalPriorityAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toGlobalPriorityAgreementViews([item, item]).count == 2)
    }
}
