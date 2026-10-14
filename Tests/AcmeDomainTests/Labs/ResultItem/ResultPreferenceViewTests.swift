@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultPreference("code-300", title: "title-206")
        let view = Labs.toResultPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultPreferenceViews([item, item]).count == 2)
    }
}
