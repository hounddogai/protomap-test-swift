@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newStrictAssessmentEntry("code-643", label: "label-14")
        let view = CareManagement.toStrictAssessmentEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toStrictAssessmentEntryViews([item, item]).count == 2)
    }
}
