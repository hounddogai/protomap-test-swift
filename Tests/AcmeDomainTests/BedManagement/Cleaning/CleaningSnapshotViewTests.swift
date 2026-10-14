@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningSnapshot("code-199", name: "name-254")
        let view = BedManagement.toCleaningSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningSnapshotViews([item, item]).count == 2)
    }
}
