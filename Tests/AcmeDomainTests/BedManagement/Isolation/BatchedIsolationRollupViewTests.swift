@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBatchedIsolationRollup("code-530", title: "title-483")
        let view = BedManagement.toBatchedIsolationRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBatchedIsolationRollupViews([item, item]).count == 2)
    }
}
