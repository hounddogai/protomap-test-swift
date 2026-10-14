@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCappedCareGapClaim("code-401", label: "label-306")
        let view = CareManagement.toCappedCareGapClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCappedCareGapClaimViews([item, item]).count == 2)
    }
}
