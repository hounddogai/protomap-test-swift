@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCleaningEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLenientCleaningEstimate("code-685", name: "name-574")
        let view = BedManagement.toLenientCleaningEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLenientCleaningEstimateViews([item, item]).count == 2)
    }
}
