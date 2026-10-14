@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCleaningEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualCleaningEstimate("code-504", name: "name-301")
        let view = BedManagement.toManualCleaningEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualCleaningEstimateViews([item, item]).count == 2)
    }
}
