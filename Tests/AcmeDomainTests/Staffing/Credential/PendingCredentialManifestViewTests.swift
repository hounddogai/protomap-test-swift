@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPendingCredentialManifest("code-388", label: "label-971")
        let view = Staffing.toPendingCredentialManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPendingCredentialManifestViews([item, item]).count == 2)
    }
}
