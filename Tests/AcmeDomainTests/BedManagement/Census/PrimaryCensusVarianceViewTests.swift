@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPrimaryCensusVariance("code-566", label: "label-251")
        let view = BedManagement.toPrimaryCensusVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPrimaryCensusVarianceViews([item, item]).count == 2)
    }
}
