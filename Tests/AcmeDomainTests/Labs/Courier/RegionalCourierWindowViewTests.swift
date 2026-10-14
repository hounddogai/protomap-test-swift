@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalCourierWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRegionalCourierWindow("code-42", title: "title-922")
        let view = Labs.toRegionalCourierWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRegionalCourierWindowViews([item, item]).count == 2)
    }
}
