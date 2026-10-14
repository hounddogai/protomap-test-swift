@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackCensusAdjustment("code-999", name: "name-764")
        let view = BedManagement.toFallbackCensusAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackCensusAdjustmentViews([item, item]).count == 2)
    }
}
