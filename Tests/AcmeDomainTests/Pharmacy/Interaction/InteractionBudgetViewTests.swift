@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionBudget("code-966", title: "title-869")
        let view = Pharmacy.toInteractionBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionBudgetViews([item, item]).count == 2)
    }
}
