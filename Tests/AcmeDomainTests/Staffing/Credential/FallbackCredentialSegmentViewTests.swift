@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialSegmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackCredentialSegment("code-132", title: "title-169")
        let view = Staffing.toFallbackCredentialSegmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackCredentialSegmentViews([item, item]).count == 2)
    }
}
