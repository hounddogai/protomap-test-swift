@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackCredentialTarget("code-691", label: "label-367")
        let view = Staffing.toFallbackCredentialTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackCredentialTargetViews([item, item]).count == 2)
    }
}
