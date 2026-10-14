@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledProgramExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledProgramException("code-558", label: "label-485")
        let view = CareManagement.toScheduledProgramExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledProgramExceptionViews([item, item]).count == 2)
    }
}
