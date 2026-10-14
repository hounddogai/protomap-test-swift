@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingIsolationExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPendingIsolationException("code-661", label: "label-787")
        let view = BedManagement.toPendingIsolationExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPendingIsolationExceptionViews([item, item]).count == 2)
    }
}
