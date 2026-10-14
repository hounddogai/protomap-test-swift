@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingModalityAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newRollingModalityAudit("code-218", title: "title-495")
        let view = Imaging.toRollingModalityAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toRollingModalityAuditViews([item, item]).count == 2)
    }
}
