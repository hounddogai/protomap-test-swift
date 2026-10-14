@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapEstimate("code-638", label: "label-464")
        let view = CareManagement.toCareGapEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapEstimateViews([item, item]).count == 2)
    }
}
