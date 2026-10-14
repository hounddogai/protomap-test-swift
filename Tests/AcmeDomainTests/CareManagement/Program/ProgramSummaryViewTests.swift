@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramSummary("code-362", title: "title-796")
        let view = CareManagement.toProgramSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramSummaryViews([item, item]).count == 2)
    }
}
