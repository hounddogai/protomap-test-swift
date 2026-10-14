@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalBedBoardManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalBedBoardManifest("code-586", label: "label-940")
        let view = BedManagement.toGlobalBedBoardManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalBedBoardManifestViews([item, item]).count == 2)
    }
}
