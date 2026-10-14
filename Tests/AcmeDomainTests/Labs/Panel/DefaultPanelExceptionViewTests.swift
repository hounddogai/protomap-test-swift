@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultPanelExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newDefaultPanelException("code-535", label: "label-781")
        let view = Labs.toDefaultPanelExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toDefaultPanelExceptionViews([item, item]).count == 2)
    }
}
