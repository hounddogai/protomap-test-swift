@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusRollup("code-243", name: "name-512")
        let view = BedManagement.toCensusRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusRollupViews([item, item]).count == 2)
    }
}
