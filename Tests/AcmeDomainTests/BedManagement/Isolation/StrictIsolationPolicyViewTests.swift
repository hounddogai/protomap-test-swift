@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictIsolationPolicy("code-295", label: "label-7")
        let view = BedManagement.toStrictIsolationPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictIsolationPolicyViews([item, item]).count == 2)
    }
}
