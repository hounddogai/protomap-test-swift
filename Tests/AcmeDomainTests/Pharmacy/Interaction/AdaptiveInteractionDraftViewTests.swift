@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInteractionDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newAdaptiveInteractionDraft("code-621", label: "label-64")
        let view = Pharmacy.toAdaptiveInteractionDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toAdaptiveInteractionDraftViews([item, item]).count == 2)
    }
}
