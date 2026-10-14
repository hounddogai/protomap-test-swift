@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredShiftDigest("code-485", title: "title-349")
        let view = Staffing.toTieredShiftDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredShiftDigestViews([item, item]).count == 2)
    }
}
