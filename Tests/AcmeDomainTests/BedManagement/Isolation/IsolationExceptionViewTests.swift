@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationException("code-230", title: "title-489")
        let view = BedManagement.toIsolationExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationExceptionViews([item, item]).count == 2)
    }
}
