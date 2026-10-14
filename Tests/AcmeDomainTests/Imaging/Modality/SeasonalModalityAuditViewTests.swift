@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalModalityAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newSeasonalModalityAudit("code-483", title: "title-875")
        let view = Imaging.toSeasonalModalityAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toSeasonalModalityAuditViews([item, item]).count == 2)
    }
}
