@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialBaseline("code-263", title: "title-472")
        let view = Staffing.toCredentialBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialBaselineViews([item, item]).count == 2)
    }
}
