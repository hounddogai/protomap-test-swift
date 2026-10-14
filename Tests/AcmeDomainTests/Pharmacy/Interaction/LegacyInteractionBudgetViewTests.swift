@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyInteractionBudget("code-58", name: "name-755")
        let view = Pharmacy.toLegacyInteractionBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyInteractionBudgetViews([item, item]).count == 2)
    }
}
