@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBedBoardClaim("code-804", name: "name-638")
        let view = BedManagement.toBedBoardClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBedBoardClaimViews([item, item]).count == 2)
    }
}
