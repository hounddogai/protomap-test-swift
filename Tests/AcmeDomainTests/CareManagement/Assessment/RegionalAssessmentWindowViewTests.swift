@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRegionalAssessmentWindow("code-858", name: "name-777")
        let view = CareManagement.toRegionalAssessmentWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRegionalAssessmentWindowViews([item, item]).count == 2)
    }
}
