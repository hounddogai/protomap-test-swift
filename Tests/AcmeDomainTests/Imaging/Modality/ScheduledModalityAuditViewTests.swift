@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledModalityAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newScheduledModalityAudit("code-208", title: "title-714")
        let view = Imaging.toScheduledModalityAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toScheduledModalityAuditViews([item, item]).count == 2)
    }
}
