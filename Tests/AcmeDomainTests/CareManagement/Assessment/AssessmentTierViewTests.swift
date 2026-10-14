@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentTier("code-229", name: "name-563")
        let view = CareManagement.toAssessmentTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentTierViews([item, item]).count == 2)
    }
}
