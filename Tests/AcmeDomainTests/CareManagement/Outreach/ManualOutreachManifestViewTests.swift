@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newManualOutreachManifest("code-839", name: "name-752")
        let view = CareManagement.toManualOutreachManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toManualOutreachManifestViews([item, item]).count == 2)
    }
}
