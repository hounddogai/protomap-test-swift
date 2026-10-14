@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInteractionBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimaryInteractionBaseline("code-203", label: "label-167")
        let view = Pharmacy.toPrimaryInteractionBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimaryInteractionBaselineViews([item, item]).count == 2)
    }
}
