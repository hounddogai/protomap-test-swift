@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalCensusRollup("code-421", name: "name-365")
        let view = BedManagement.toGlobalCensusRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalCensusRollupViews([item, item]).count == 2)
    }
}
