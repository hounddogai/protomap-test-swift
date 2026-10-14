@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierWindow("code-303", title: "title-349")
        let view = Labs.toCourierWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierWindowViews([item, item]).count == 2)
    }
}
