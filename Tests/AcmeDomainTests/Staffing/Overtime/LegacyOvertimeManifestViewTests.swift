@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyOvertimeManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLegacyOvertimeManifest("code-876", name: "name-87")
        let view = Staffing.toLegacyOvertimeManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLegacyOvertimeManifestViews([item, item]).count == 2)
    }
}
