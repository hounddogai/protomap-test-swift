@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newBatchedIsolationWindow("code-186", label: "label-296")
        let view = BedManagement.toBatchedIsolationWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toBatchedIsolationWindowViews([item, item]).count == 2)
    }
}
