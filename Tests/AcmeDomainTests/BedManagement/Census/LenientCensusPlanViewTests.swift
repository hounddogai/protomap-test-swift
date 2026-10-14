@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusPlanViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientCensusPlan("code-549", title: "title-205")
        let view = BedManagement.toLenientCensusPlanView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientCensusPlanViews([item, item]).count == 2)
    }
}
