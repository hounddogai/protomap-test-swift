@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCredentialManifest("code-776", name: "name-503")
        let view = Staffing.toCredentialManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCredentialManifestViews([item, item]).count == 2)
    }
}
