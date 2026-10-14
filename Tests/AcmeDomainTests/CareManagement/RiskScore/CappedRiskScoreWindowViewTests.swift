@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedRiskScoreWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCappedRiskScoreWindow("code-318", title: "title-111")
        let view = CareManagement.toCappedRiskScoreWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCappedRiskScoreWindowViews([item, item]).count == 2)
    }
}
