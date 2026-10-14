@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultAssessmentEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newDefaultAssessmentEntry("code-606", name: "name-730")
        let view = CareManagement.toDefaultAssessmentEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toDefaultAssessmentEntryViews([item, item]).count == 2)
    }
}
