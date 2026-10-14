@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelBudget("code-86", title: "title-572")
        let view = Labs.toPanelBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelBudgetViews([item, item]).count == 2)
    }
}
