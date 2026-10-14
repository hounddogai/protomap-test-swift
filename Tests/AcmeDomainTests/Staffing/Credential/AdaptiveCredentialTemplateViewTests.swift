@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveCredentialTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveCredentialTemplate("code-227", name: "name-789")
        let view = Staffing.toAdaptiveCredentialTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveCredentialTemplateViews([item, item]).count == 2)
    }
}
