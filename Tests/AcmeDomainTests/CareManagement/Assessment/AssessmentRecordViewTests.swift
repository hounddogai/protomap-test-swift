@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentRecord("code-754", title: "title-309")
        let view = CareManagement.toAssessmentRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentRecordViews([item, item]).count == 2)
    }
}
