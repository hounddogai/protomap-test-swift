@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentMapping("code-447", name: "name-906")
        let view = CareManagement.toAssessmentMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentMappingViews([item, item]).count == 2)
    }
}
