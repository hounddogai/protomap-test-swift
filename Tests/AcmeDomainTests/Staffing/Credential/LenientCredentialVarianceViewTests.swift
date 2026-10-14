@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientCredentialVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLenientCredentialVariance("code-126", label: "label-305")
        let view = Staffing.toLenientCredentialVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLenientCredentialVarianceViews([item, item]).count == 2)
    }
}
