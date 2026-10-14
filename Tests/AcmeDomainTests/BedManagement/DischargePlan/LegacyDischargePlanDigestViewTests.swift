@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyDischargePlanDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyDischargePlanDigest("code-317", label: "label-51")
        let view = BedManagement.toLegacyDischargePlanDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyDischargePlanDigestViews([item, item]).count == 2)
    }
}
