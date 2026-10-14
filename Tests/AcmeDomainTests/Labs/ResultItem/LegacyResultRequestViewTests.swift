@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyResultRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyResultRequest("code-593", title: "title-772")
        let view = Labs.toLegacyResultRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyResultRequestViews([item, item]).count == 2)
    }
}
