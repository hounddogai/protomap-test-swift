@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationTarget("code-882", label: "label-711")
        let view = BedManagement.toIsolationTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationTargetViews([item, item]).count == 2)
    }
}
