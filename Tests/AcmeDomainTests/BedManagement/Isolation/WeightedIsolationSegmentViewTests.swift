@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedIsolationSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newWeightedIsolationSegment("code-323", name: "name-364")
        let view = BedManagement.toWeightedIsolationSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toWeightedIsolationSegmentViews([item, item]).count == 2)
    }
}
