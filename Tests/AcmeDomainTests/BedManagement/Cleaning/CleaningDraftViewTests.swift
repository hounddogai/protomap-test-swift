@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCleaningDraft("code-414", title: "title-802")
        let view = BedManagement.toCleaningDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCleaningDraftViews([item, item]).count == 2)
    }
}
