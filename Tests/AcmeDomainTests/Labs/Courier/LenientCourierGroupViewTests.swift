@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientCourierGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLenientCourierGroup("code-790", title: "title-461")
        let view = Labs.toLenientCourierGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLenientCourierGroupViews([item, item]).count == 2)
    }
}
