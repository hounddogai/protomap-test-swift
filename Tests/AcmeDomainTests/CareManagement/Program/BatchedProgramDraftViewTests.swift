@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedProgramDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedProgramDraft("code-796", title: "title-171")
        let view = CareManagement.toBatchedProgramDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedProgramDraftViews([item, item]).count == 2)
    }
}
