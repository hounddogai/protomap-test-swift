@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultBundle("code-482", title: "title-635")
        let view = Labs.toResultBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultBundleViews([item, item]).count == 2)
    }
}
