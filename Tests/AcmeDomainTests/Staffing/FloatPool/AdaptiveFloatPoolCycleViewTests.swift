@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveFloatPoolCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveFloatPoolCycle("code-996", label: "label-59")
        let view = Staffing.toAdaptiveFloatPoolCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveFloatPoolCycleViews([item, item]).count == 2)
    }
}
