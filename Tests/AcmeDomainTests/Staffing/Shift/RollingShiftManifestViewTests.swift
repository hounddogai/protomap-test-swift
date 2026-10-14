@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingShiftManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRollingShiftManifest("code-511", name: "name-611")
        let view = Staffing.toRollingShiftManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRollingShiftManifestViews([item, item]).count == 2)
    }
}
