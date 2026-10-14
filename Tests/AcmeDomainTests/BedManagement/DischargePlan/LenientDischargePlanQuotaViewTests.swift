@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientDischargePlanQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientDischargePlanQuota("code-362", label: "label-262")
        let view = BedManagement.toLenientDischargePlanQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientDischargePlanQuotaViews([item, item]).count == 2)
    }
}
