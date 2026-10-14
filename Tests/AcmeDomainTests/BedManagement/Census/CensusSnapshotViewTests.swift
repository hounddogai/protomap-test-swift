@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusSnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusSnapshot("code-671", label: "label-643")
        let view = BedManagement.toCensusSnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusSnapshotViews([item, item]).count == 2)
    }
}
