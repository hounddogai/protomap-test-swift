@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialEstimate("code-101", label: "label-174")
        let view = Staffing.toCredentialEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialEstimateViews([item, item]).count == 2)
    }
}
