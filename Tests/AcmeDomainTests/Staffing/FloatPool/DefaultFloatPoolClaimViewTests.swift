@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultFloatPoolClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newDefaultFloatPoolClaim("code-246", label: "label-750")
        let view = Staffing.toDefaultFloatPoolClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toDefaultFloatPoolClaimViews([item, item]).count == 2)
    }
}
