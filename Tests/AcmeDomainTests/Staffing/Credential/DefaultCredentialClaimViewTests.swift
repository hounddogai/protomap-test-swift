@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultCredentialClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newDefaultCredentialClaim("code-199", title: "title-340")
        let view = Staffing.toDefaultCredentialClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toDefaultCredentialClaimViews([item, item]).count == 2)
    }
}
