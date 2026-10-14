@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackIsolationGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackIsolationGroup("code-846", label: "label-295")
        let view = BedManagement.toFallbackIsolationGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackIsolationGroupViews([item, item]).count == 2)
    }
}
