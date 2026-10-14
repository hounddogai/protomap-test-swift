@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newProgramEntry("code-714", label: "label-550")
        let view = CareManagement.toProgramEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toProgramEntryViews([item, item]).count == 2)
    }
}
