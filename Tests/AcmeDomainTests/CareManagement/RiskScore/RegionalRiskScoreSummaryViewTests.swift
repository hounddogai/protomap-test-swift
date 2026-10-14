@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalRiskScoreSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRegionalRiskScoreSummary("code-17", title: "title-540")
        let view = CareManagement.toRegionalRiskScoreSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRegionalRiskScoreSummaryViews([item, item]).count == 2)
    }
}
