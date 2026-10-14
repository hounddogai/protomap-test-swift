@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingCourierPreference("code-97", label: "label-119")
        let view = Labs.toPendingCourierPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingCourierPreferenceViews([item, item]).count == 2)
    }
}
