@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryBedBoardMetric("code-764", name: "name-773")
        let view = BedManagement.toPrimaryBedBoardMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryBedBoardMetricViews([item, item]).count == 2)
    }
}
