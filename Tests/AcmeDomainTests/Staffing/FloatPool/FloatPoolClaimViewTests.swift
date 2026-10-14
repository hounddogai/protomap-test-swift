@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolClaim("code-345", label: "label-865")
        let view = Staffing.toFloatPoolClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolClaimViews([item, item]).count == 2)
    }
}
