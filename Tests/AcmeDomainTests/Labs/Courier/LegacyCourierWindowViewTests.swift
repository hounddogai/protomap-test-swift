@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyCourierWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyCourierWindow("code-347", title: "title-751")
        let view = Labs.toLegacyCourierWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyCourierWindowViews([item, item]).count == 2)
    }
}
