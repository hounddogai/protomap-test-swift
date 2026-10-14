@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedPanelBudget("code-425", title: "title-472")
        let view = Labs.toCappedPanelBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedPanelBudgetViews([item, item]).count == 2)
    }
}
