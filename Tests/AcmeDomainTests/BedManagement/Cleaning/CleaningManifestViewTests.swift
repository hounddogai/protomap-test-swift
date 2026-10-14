@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningManifest("code-534", label: "label-607")
        let view = BedManagement.toCleaningManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningManifestViews([item, item]).count == 2)
    }
}
