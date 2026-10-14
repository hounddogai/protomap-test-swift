@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionPreference("code-671", label: "label-168")
        let view = Pharmacy.toInteractionPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionPreferenceViews([item, item]).count == 2)
    }
}
