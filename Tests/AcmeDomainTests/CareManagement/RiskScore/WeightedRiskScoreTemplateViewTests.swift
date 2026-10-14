@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScoreTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newWeightedRiskScoreTemplate("code-875", name: "name-2")
        let view = CareManagement.toWeightedRiskScoreTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toWeightedRiskScoreTemplateViews([item, item]).count == 2)
    }
}
