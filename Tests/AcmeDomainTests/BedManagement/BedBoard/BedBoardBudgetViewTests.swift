@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardBudget("code-93", name: "name-168")
        let view = BedManagement.toBedBoardBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardBudgetViews([item, item]).count == 2)
    }
}
