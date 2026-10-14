@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInteractionBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedInteractionBudget("code-181", title: "title-592")
        let view = Pharmacy.toBatchedInteractionBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedInteractionBudgetViews([item, item]).count == 2)
    }
}
