@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackResultProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newFallbackResultProfile("code-828", title: "title-478")
        let view = Labs.toFallbackResultProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toFallbackResultProfileViews([item, item]).count == 2)
    }
}
