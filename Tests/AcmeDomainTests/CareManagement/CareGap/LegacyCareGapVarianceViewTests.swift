@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLegacyCareGapVariance("code-920", name: "name-461")
        let view = CareManagement.toLegacyCareGapVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLegacyCareGapVarianceViews([item, item]).count == 2)
    }
}
