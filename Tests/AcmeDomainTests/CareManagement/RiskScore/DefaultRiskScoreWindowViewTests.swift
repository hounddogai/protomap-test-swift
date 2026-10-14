@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newDefaultRiskScoreWindow("code-916", title: "title-530")
        let view = CareManagement.toDefaultRiskScoreWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toDefaultRiskScoreWindowViews([item, item]).count == 2)
    }
}
