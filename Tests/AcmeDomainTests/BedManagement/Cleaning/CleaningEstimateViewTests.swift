@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningEstimate("code-667", name: "name-36")
        let view = BedManagement.toCleaningEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningEstimateViews([item, item]).count == 2)
    }
}
