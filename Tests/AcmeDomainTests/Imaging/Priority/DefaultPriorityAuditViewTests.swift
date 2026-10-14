@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultPriorityAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newDefaultPriorityAudit("code-148", name: "name-288")
        let view = Imaging.toDefaultPriorityAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toDefaultPriorityAuditViews([item, item]).count == 2)
    }
}
