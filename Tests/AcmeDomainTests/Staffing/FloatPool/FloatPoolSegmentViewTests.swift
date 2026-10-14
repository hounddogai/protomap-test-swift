@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolSegment("code-739", title: "title-46")
        let view = Staffing.toFloatPoolSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolSegmentViews([item, item]).count == 2)
    }
}
