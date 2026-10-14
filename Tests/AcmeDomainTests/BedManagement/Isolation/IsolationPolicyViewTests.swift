@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationPolicy("code-208", label: "label-735")
        let view = BedManagement.toIsolationPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationPolicyViews([item, item]).count == 2)
    }
}
