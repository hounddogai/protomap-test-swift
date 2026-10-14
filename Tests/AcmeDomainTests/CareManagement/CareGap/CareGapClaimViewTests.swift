@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapClaim("code-364", name: "name-651")
        let view = CareManagement.toCareGapClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapClaimViews([item, item]).count == 2)
    }
}
