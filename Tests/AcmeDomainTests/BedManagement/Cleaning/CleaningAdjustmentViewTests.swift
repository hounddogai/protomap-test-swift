@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningAdjustment("code-927", label: "label-937")
        let view = BedManagement.toCleaningAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningAdjustmentViews([item, item]).count == 2)
    }
}
