@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusTier("code-995", name: "name-41")
        let view = BedManagement.toCensusTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusTierViews([item, item]).count == 2)
    }
}
