@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLegacyCareGapEstimate("code-677", name: "name-281")
        let view = CareManagement.toLegacyCareGapEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLegacyCareGapEstimateViews([item, item]).count == 2)
    }
}
