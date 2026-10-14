@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredResultRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newTieredResultRequest("code-108", title: "title-588")
        let view = Labs.toTieredResultRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toTieredResultRequestViews([item, item]).count == 2)
    }
}
