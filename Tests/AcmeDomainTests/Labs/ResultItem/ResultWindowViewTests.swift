@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultWindow("code-789", title: "title-544")
        let view = Labs.toResultWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultWindowViews([item, item]).count == 2)
    }
}
