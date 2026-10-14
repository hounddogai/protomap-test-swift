@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCleaningManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryCleaningManifest("code-151", title: "title-56")
        let view = BedManagement.toPrimaryCleaningManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryCleaningManifestViews([item, item]).count == 2)
    }
}
