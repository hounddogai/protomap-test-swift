@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentDigest("code-757", label: "label-315")
        let view = CareManagement.toAssessmentDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentDigestViews([item, item]).count == 2)
    }
}
