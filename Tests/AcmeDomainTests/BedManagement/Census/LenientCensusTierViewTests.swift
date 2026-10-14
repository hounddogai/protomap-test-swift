@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientCensusTier("code-579", title: "title-668")
        let view = BedManagement.toLenientCensusTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientCensusTierViews([item, item]).count == 2)
    }
}
