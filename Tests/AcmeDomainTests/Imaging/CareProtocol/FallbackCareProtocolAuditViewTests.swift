@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newFallbackCareProtocolAudit("code-109", title: "title-931")
        let view = Imaging.toFallbackCareProtocolAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toFallbackCareProtocolAuditViews([item, item]).count == 2)
    }
}
