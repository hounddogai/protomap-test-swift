@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRollingProgramDraft("code-199", name: "name-825")
        let view = CareManagement.toRollingProgramDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRollingProgramDraftViews([item, item]).count == 2)
    }
}
