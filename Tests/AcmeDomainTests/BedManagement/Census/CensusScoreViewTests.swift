@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusScore("code-979", label: "label-774")
        let view = BedManagement.toCensusScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusScoreViews([item, item]).count == 2)
    }
}
