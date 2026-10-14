@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newDefaultProgramBaseline("code-883", label: "label-405")
        let view = CareManagement.toDefaultProgramBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toDefaultProgramBaselineViews([item, item]).count == 2)
    }
}
