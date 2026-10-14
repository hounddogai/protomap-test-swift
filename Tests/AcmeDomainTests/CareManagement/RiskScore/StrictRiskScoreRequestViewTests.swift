@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictRiskScoreRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newStrictRiskScoreRequest("code-195", name: "name-209")
        let view = CareManagement.toStrictRiskScoreRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toStrictRiskScoreRequestViews([item, item]).count == 2)
    }
}
