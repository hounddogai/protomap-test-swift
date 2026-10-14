@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolScore("code-821", label: "label-595")
        let view = Staffing.toFloatPoolScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolScoreViews([item, item]).count == 2)
    }
}
