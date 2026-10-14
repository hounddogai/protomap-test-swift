@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveCredentialMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveCredentialMapping("code-973", label: "label-790")
        let view = Staffing.toAdaptiveCredentialMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveCredentialMappingViews([item, item]).count == 2)
    }
}
