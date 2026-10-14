@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialSummary("code-342", name: "name-508")
        let view = Staffing.toCredentialSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialSummaryViews([item, item]).count == 2)
    }
}
