@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientCensusTarget("code-402", title: "title-105")
        let view = BedManagement.toLenientCensusTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientCensusTargetViews([item, item]).count == 2)
    }
}
