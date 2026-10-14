@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalCleaningThreshold("code-693", label: "label-571")
        let view = BedManagement.toGlobalCleaningThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalCleaningThresholdViews([item, item]).count == 2)
    }
}
