@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierRequest("code-563", title: "title-809")
        let view = Labs.toCourierRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierRequestViews([item, item]).count == 2)
    }
}
