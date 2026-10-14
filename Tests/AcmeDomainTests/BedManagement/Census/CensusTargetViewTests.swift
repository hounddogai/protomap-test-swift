@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusTarget("code-610", label: "label-975")
        let view = BedManagement.toCensusTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusTargetViews([item, item]).count == 2)
    }
}
