@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultRequest("code-734", title: "title-877")
        let view = Labs.toResultRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultRequestViews([item, item]).count == 2)
    }
}
