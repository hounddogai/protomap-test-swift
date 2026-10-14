@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialCycle("code-744", label: "label-844")
        let view = Staffing.toCredentialCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialCycleViews([item, item]).count == 2)
    }
}
