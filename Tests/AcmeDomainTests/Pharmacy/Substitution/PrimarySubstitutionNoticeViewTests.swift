@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimarySubstitutionNotice("code-769", label: "label-42")
        let view = Pharmacy.toPrimarySubstitutionNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimarySubstitutionNoticeViews([item, item]).count == 2)
    }
}
