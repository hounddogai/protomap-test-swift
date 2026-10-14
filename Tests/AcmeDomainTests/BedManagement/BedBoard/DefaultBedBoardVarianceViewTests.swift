@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDefaultBedBoardVariance("code-121", label: "label-81")
        let view = BedManagement.toDefaultBedBoardVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDefaultBedBoardVarianceViews([item, item]).count == 2)
    }
}
