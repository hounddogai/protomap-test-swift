@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictDischargePlanPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictDischargePlanPolicy("code-834", name: "name-231")
        let view = BedManagement.toStrictDischargePlanPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictDischargePlanPolicyViews([item, item]).count == 2)
    }
}
