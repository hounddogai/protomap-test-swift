@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeBudget("code-738", label: "label-22")
        let view = Labs.toReferenceRangeBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeBudgetViews([item, item]).count == 2)
    }
}
