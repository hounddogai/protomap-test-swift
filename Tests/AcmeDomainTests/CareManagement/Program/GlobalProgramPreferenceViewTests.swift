@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalProgramPreference("code-974", title: "title-34")
        let view = CareManagement.toGlobalProgramPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalProgramPreferenceViews([item, item]).count == 2)
    }
}
