@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyInteractionSegment("code-562", label: "label-238")
        let view = Pharmacy.toLegacyInteractionSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyInteractionSegmentViews([item, item]).count == 2)
    }
}
