@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGoalVariance("code-949", label: "label-718")
        let view = CareManagement.toGoalVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGoalVarianceViews([item, item]).count == 2)
    }
}
