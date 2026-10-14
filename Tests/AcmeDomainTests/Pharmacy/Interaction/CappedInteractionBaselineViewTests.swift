@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInteractionBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newCappedInteractionBaseline("code-569", title: "title-444")
        let view = Pharmacy.toCappedInteractionBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toCappedInteractionBaselineViews([item, item]).count == 2)
    }
}
