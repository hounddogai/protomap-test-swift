@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDefaultCleaningManifest("code-736", label: "label-953")
        let view = BedManagement.toDefaultCleaningManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDefaultCleaningManifestViews([item, item]).count == 2)
    }
}
