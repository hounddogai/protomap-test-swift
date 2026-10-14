@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolPreference("code-943", name: "name-228")
        let view = Staffing.toFloatPoolPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolPreferenceViews([item, item]).count == 2)
    }
}
