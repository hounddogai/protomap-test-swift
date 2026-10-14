@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newCareGapMilestone("code-859", name: "name-134")
        let view = CareManagement.toCareGapMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toCareGapMilestoneViews([item, item]).count == 2)
    }
}
