@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newGlobalCourierMapping("code-978", title: "title-554")
        let view = Labs.toGlobalCourierMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toGlobalCourierMappingViews([item, item]).count == 2)
    }
}
