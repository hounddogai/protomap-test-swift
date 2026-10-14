@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledProgramProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newScheduledProgramProfile("code-15", title: "title-468")
        let view = CareManagement.toScheduledProgramProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toScheduledProgramProfileViews([item, item]).count == 2)
    }
}
