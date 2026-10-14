@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSubstitutionSegment("code-614", label: "label-653")
        let view = Pharmacy.toSubstitutionSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSubstitutionSegmentViews([item, item]).count == 2)
    }
}
