@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolEstimate("code-459", name: "name-634")
        let view = Staffing.toFloatPoolEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolEstimateViews([item, item]).count == 2)
    }
}
