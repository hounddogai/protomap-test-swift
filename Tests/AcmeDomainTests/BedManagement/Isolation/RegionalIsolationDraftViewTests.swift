@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRegionalIsolationDraft("code-893", name: "name-70")
        let view = BedManagement.toRegionalIsolationDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRegionalIsolationDraftViews([item, item]).count == 2)
    }
}
