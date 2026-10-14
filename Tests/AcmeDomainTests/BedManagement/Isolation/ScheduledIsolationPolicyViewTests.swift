@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledIsolationPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledIsolationPolicy("code-960", name: "name-433")
        let view = BedManagement.toScheduledIsolationPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledIsolationPolicyViews([item, item]).count == 2)
    }
}
