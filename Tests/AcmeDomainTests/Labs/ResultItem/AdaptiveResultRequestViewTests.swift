@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAdaptiveResultRequest("code-155", label: "label-457")
        let view = Labs.toAdaptiveResultRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAdaptiveResultRequestViews([item, item]).count == 2)
    }
}
