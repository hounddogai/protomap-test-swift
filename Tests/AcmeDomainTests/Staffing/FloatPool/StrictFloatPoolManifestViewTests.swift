@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictFloatPoolManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictFloatPoolManifest("code-264", name: "name-390")
        let view = Staffing.toStrictFloatPoolManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictFloatPoolManifestViews([item, item]).count == 2)
    }
}
