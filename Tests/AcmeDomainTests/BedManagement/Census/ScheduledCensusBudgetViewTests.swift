@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledCensusBudget("code-97", name: "name-153")
        let view = BedManagement.toScheduledCensusBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledCensusBudgetViews([item, item]).count == 2)
    }
}
