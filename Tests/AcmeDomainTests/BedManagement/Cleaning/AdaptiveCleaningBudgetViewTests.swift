@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newAdaptiveCleaningBudget("code-11", label: "label-445")
        let view = BedManagement.toAdaptiveCleaningBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toAdaptiveCleaningBudgetViews([item, item]).count == 2)
    }
}
