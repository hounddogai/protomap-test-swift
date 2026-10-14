@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingResultPreference("code-48", label: "label-230")
        let view = Labs.toPendingResultPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingResultPreferenceViews([item, item]).count == 2)
    }
}
