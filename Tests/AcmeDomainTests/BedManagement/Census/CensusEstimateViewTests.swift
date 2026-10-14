@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusEstimate("code-256", label: "label-780")
        let view = BedManagement.toCensusEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusEstimateViews([item, item]).count == 2)
    }
}
