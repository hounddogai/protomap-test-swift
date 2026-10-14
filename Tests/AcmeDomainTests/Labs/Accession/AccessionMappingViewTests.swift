@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionMapping("code-774", title: "title-972")
        let view = Labs.toAccessionMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionMappingViews([item, item]).count == 2)
    }
}
