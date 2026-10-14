@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCleaningWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newManualCleaningWindow("code-592", label: "label-769")
        let view = BedManagement.toManualCleaningWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toManualCleaningWindowViews([item, item]).count == 2)
    }
}
