@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusBundle("code-727", title: "title-275")
        let view = BedManagement.toCensusBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusBundleViews([item, item]).count == 2)
    }
}
