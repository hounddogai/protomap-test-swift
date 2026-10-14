@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackBedBoardVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackBedBoardVariance("code-547", name: "name-566")
        let view = BedManagement.toFallbackBedBoardVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackBedBoardVarianceViews([item, item]).count == 2)
    }
}
