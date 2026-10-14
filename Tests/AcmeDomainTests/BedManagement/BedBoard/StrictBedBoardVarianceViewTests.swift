@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newStrictBedBoardVariance("code-503", name: "name-593")
        let view = BedManagement.toStrictBedBoardVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toStrictBedBoardVarianceViews([item, item]).count == 2)
    }
}
