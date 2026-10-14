@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusBatch("code-720", name: "name-380")
        let view = BedManagement.toCensusBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusBatchViews([item, item]).count == 2)
    }
}
