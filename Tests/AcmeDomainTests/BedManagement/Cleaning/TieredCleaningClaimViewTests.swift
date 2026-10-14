@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTieredCleaningClaim("code-453", label: "label-96")
        let view = BedManagement.toTieredCleaningClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTieredCleaningClaimViews([item, item]).count == 2)
    }
}
