@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledCensusPlan("code-337", title: "title-289")
        let view = BedManagement.toScheduledCensusPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledCensusPlanViews([item, item]).count == 2)
    }
}
