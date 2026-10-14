@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapVariance("code-164", title: "title-38")
        let view = CareManagement.toCareGapVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapVarianceViews([item, item]).count == 2)
    }
}
