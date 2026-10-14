@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationMapping("code-843", title: "title-28")
        let view = BedManagement.toIsolationMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationMappingViews([item, item]).count == 2)
    }
}
