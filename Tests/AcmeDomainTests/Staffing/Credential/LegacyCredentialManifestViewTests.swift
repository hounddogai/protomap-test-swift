@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newLegacyCredentialManifest("code-545", title: "title-612")
        let view = Staffing.toLegacyCredentialManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toLegacyCredentialManifestViews([item, item]).count == 2)
    }
}
