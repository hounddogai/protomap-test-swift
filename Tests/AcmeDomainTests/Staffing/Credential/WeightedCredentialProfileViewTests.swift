@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newWeightedCredentialProfile("code-919", name: "name-364")
        let view = Staffing.toWeightedCredentialProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toWeightedCredentialProfileViews([item, item]).count == 2)
    }
}
