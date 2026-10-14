@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallPreference("code-813", label: "label-409")
        let view = Pharmacy.toRecallPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallPreferenceViews([item, item]).count == 2)
    }
}
