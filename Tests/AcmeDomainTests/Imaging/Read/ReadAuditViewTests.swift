@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newReadAudit("code-417", label: "label-38")
        let view = Imaging.toReadAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toReadAuditViews([item, item]).count == 2)
    }
}
