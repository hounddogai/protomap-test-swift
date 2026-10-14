@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultOverride("code-87", label: "label-57")
        let view = Labs.toResultOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultOverrideViews([item, item]).count == 2)
    }
}
