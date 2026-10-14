@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalIsolationThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newSeasonalIsolationThreshold("code-638", label: "label-788")
        let view = BedManagement.toSeasonalIsolationThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toSeasonalIsolationThresholdViews([item, item]).count == 2)
    }
}
