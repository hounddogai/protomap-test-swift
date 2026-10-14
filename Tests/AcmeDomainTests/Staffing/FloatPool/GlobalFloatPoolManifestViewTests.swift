@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newGlobalFloatPoolManifest("code-765", title: "title-494")
        let view = Staffing.toGlobalFloatPoolManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toGlobalFloatPoolManifestViews([item, item]).count == 2)
    }
}
