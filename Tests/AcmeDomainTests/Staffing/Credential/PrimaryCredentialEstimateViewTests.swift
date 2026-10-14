@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryCredentialEstimate("code-607", title: "title-114")
        let view = Staffing.toPrimaryCredentialEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryCredentialEstimateViews([item, item]).count == 2)
    }
}
