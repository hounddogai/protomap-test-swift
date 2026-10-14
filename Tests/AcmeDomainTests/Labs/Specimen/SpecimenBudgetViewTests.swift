@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenBudget("code-283", label: "label-886")
        let view = Labs.toSpecimenBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenBudgetViews([item, item]).count == 2)
    }
}
