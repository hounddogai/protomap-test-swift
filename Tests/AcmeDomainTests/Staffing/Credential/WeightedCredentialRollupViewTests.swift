@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newWeightedCredentialRollup("code-652", label: "label-354")
        let view = Staffing.toWeightedCredentialRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toWeightedCredentialRollupViews([item, item]).count == 2)
    }
}
