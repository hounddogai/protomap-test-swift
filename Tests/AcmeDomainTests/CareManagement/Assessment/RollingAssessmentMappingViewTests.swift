@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRollingAssessmentMapping("code-126", name: "name-402")
        let view = CareManagement.toRollingAssessmentMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRollingAssessmentMappingViews([item, item]).count == 2)
    }
}
