@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialRecord("code-900", label: "label-637")
        let view = Staffing.toCredentialRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialRecordViews([item, item]).count == 2)
    }
}
