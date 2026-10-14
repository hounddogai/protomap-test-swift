@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newOutreachManifest("code-474", name: "name-81")
        let view = CareManagement.toOutreachManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toOutreachManifestViews([item, item]).count == 2)
    }
}
