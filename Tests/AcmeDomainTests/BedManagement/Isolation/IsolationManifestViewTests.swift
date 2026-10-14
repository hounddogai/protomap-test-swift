@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationManifest("code-541", label: "label-629")
        let view = BedManagement.toIsolationManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationManifestViews([item, item]).count == 2)
    }
}
