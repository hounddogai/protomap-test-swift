@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedBedBoardClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newWeightedBedBoardClaim("code-163", name: "name-900")
        let view = BedManagement.toWeightedBedBoardClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toWeightedBedBoardClaimViews([item, item]).count == 2)
    }
}
