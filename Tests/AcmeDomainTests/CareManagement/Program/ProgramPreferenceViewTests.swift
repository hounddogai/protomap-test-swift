@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramPreference("code-149", title: "title-992")
        let view = CareManagement.toProgramPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramPreferenceViews([item, item]).count == 2)
    }
}
