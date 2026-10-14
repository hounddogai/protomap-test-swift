@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusBaseline("code-216", label: "label-490")
        let view = BedManagement.toCensusBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusBaselineViews([item, item]).count == 2)
    }
}
