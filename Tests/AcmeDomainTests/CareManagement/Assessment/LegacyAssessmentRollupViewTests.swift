@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyAssessmentRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLegacyAssessmentRollup("code-130", label: "label-409")
        let view = CareManagement.toLegacyAssessmentRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLegacyAssessmentRollupViews([item, item]).count == 2)
    }
}
