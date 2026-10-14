@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCleaningWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newPendingCleaningWindow("code-292", label: "label-107")
        let view = BedManagement.toPendingCleaningWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toPendingCleaningWindowViews([item, item]).count == 2)
    }
}
