@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictOvertimeManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictOvertimeManifest("code-323", name: "name-841")
        let view = Staffing.toStrictOvertimeManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictOvertimeManifestViews([item, item]).count == 2)
    }
}
