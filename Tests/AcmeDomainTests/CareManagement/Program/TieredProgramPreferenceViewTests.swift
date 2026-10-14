@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredProgramPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredProgramPreference("code-129", name: "name-745")
        let view = CareManagement.toTieredProgramPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredProgramPreferenceViews([item, item]).count == 2)
    }
}
